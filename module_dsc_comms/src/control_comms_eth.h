/**
 * Module:  module_dsc_comms
 * Version: 1v0alpha0
 * Build:   8234dc1c93e3702c697f99474a8ca1e7d28a61cc
 * File:    control_comms_eth.h
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
#ifndef _CONTROL_COMMS_ETH_H_
#define _CONTROL_COMMS_ETH_H_
#include <dsc_config.h>

#ifdef BLDC_BASIC
void do_comms_eth( chanend c_commands_eth,chanend c_commands_eth2, chanend tcp_svr,chanend c_eth_gui_en );
#endif

#ifdef BLDC_FOC
void do_comms_eth( chanend c_commands_eth, chanend tcp_svr,chanend c_eth_gui_en);
#endif
#endif /* _CONTROL_COMMS_ETH_H_ */
