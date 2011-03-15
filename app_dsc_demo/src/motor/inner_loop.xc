/**
 * Module:  app_dsc_demo
 * Version: 1v0alpha1
 * Build:   60a90cca6296c0154ccc44e1375cc3966292f74e
 * File:    inner_loop.xc
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2010
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/                                   
#include <xs1.h>
#include "inner_loop.h"
#include "hall_input.h"
#include "pwm_cli.h"
#include "clarke.h"
#include "park.h"
#include "pid_regulator.h"
#include "adc_filter.h"
#include "adc_client.h"
#include "hall_client.h"
#include <print.h>

#define ADC_DELAY 15
#pragma unsafe arrays
void run_motor ( chanend c_pwm, chanend c_hall, chanend c_adc, chanend c_control, chanend ?c_logging )
{
	/* transform variables */
	int Ia_in = 0, Ib_in = 0, Ic_in = 0;
	int alpha_out = 0, beta_out = 0;
	int Id_in = 0, Iq_in = 0;
	int id_out = 0, iq_out = 0;
	int alpha_in = 0, beta_in = 0;
	int Va = 0, Vb = 0, Vc = 0;

	unsigned theta = 0;
	unsigned pwm[3] = {0, 0, 0};
	unsigned cmd;

	int log_flag = 1;

	unsigned delta, speed = 0;

	int Id_err = 0;
	int Iq_err = 0;
	
	pid_data pid_d, pid_q;

	unsigned iq_set_point = 0;
	unsigned id_set_point = 0; // always zero for BLDC

	unsigned ts;
	timer t;

	/* allow the WD to get going */
	t :> ts;
	t when timerafter(ts+100000000) :> ts;

	/* PID control initialisation... will need tuning! */
	#define MOTOR_P ((6*32768))
	#define MOTOR_I 100
	#define MOTOR_D 0
	init_pid( MOTOR_P, MOTOR_I, MOTOR_D, pid_q);
	init_pid( MOTOR_P, MOTOR_I, MOTOR_D, pid_d);

	/* zero pwm */
	pwm[0] = 0;
	pwm[1] = 0;
	pwm[2] = 0;

	/* ADC centrepoint calibration */
	update_pwm( c_pwm, pwm );
	do_adc_calibration( c_adc );

	/* update PWM */
	update_pwm( c_pwm, pwm );

	iq_set_point = 0;

	/* main loop */
	while (1)
	{

		select
		{
		/* respond to outer loop demand */
		case c_control :> cmd:
			iq_set_point = cmd;
			break;
		default:

			/* get ADC readings */
			{Ia_in, Ib_in, Ic_in} = get_adc_vals_calibrated_int16( c_adc );

			/* get hall information */
			{theta,speed,delta} = get_hall_pos_speed_delta( c_hall );
			
			/*
			 * What follows is an example of function calls that would be required to complete a
			 * FOC algorithm. This is an example only and is not functional!
			 */

			/* calculate alpha_in and beta_in */
			clarke_transform(alpha_in, beta_in, Ia_in, Ib_in, Ic_in);

			/* calculate Id_in and Iq_in */
			park_transform( Id_in, Iq_in, alpha_in, beta_in, theta  );

			/* apply PID control to Iq and Id */
			Iq_err = iq_set_point - Iq_in;
			Id_err = id_set_point - Id_in;
			iq_out = pid_regulator_delta_cust_error( Iq_err, pid_q );
			id_out = pid_regulator_delta_cust_error( Id_err, pid_d );

			/* inverse park  [d,q] to [alpha, beta] */
			inverse_park_transform( alpha_out, beta_out, id_out, iq_out, theta  );

			/* do inverse clark to get voltages */
			inverse_clarke_transform( Va, Vb, Vc, alpha_out, beta_out );

			/* scale to 12bit unsigned for PWM output */
			pwm[0] = (Va + 32768) >> 4;
			pwm[1] = (Vb + 32768) >> 4;
			pwm[2] = (Vc + 32768) >> 4;

			/* clamp to avoid switching issues */
			for (int j = 0; j < 3; j++)
			{
				if (pwm[j] > 3900)
					pwm[j] = 3900;
				if (pwm[j] < 196 && pwm[j] != 0)
					pwm[j] = 196;
			}

			// Send the data to the logger
			if ( ( log_flag == 1 ) && ( !isnull( c_logging ) ) )
			{
				c_logging <: 1;
				outuint( c_logging, Ia_in );
				outuint( c_logging, Ib_in );
				outuint( c_logging, Ic_in );
				outuint( c_logging, iq_set_point );
				outuint( c_logging, Iq_in );
				outuint( c_logging, Id_in );
				outuint( c_logging, iq_out );
				outuint( c_logging, id_out );
				outuint( c_logging, theta );
				outuint( c_logging, speed );
				outuint( c_logging, delta );
				outuint( c_logging, pwm[0] );
				outuint( c_logging, pwm[1] );
				outuint( c_logging, pwm[2] );
			}

			// Update the PWM values
			update_pwm( c_pwm, pwm );

			break;
		}


	}
}