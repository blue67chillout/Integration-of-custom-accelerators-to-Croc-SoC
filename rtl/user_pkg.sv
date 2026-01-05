// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

`include "obi/typedef.svh"

// package user_pkg;

//   ////////////////////////////////
//   // User Manager Address maps //
//   ///////////////////////////////
  
//   // None


//   /////////////////////////////////////
//   // User Subordinate Address maps ////
//   /////////////////////////////////////

//   localparam int unsigned NumUserDomainSubordinates = 1;

//   localparam bit [31:0] MacAccelAddrOffset = croc_pkg::UserBaseAddr;        // 32'h2000_0000;
//   localparam bit [31:0] MacAccelAddrRange  = 32'h0000_1000;                 // 4KB address space

//   localparam int unsigned NumDemuxSbrRules  = (NumUserDomainSubordinates > 0) ? NumUserDomainSubordinates : 1; // number of address rules in the decoder
//   localparam int unsigned NumDemuxSbr       = NumDemuxSbrRules + 1; // additional OBI error, used for signal arrays

//   // Enum for bus indices
//   typedef enum int {
//     UserMacAccel = 0,
//     UserError = 1
//   } user_demux_outputs_e;

//   // Address rules given to address decoder
//   localparam croc_pkg::addr_map_rule_t [NumDemuxSbrRules-1:0] user_addr_map = '{
//     '{ idx: UserMacAccel, start_addr: MacAccelAddrOffset, end_addr: MacAccelAddrOffset + MacAccelAddrRange }
//   };

// endpackage

`include "obi/typedef.svh"

package user_pkg;

  /////////////////////////////////////
  // User Subordinate Address maps ////
  /////////////////////////////////////

  // Number of user subordinates (ROM + MAC)
  localparam int unsigned NumUserDomainSubordinates = 2;

  // Base of user domain
  localparam bit [31:0] UserBaseAddr = croc_pkg::UserBaseAddr; // 0x2000_0000

  // --- User ROM ---
  localparam bit [31:0] UserRomAddrOffset = UserBaseAddr;          // 0x2000_0000
  localparam bit [31:0] UserRomAddrRange  = 32'h0000_1000;         // 4 KB

  // --- MAC Accelerator ---
  localparam bit [31:0] MacAccelAddrOffset = UserBaseAddr + 32'h0000_1000; // 0x2000_1000
  localparam bit [31:0] MacAccelAddrRange  = 32'h0000_1000;                 // 4 KB

  // Address decoder parameters
  localparam int unsigned NumDemuxSbrRules =
    (NumUserDomainSubordinates > 0) ? NumUserDomainSubordinates : 1;

  localparam int unsigned NumDemuxSbr =
    NumDemuxSbrRules + 1; // +1 for OBI error port

  // Enum for demux outputs
  typedef enum int {
    UserRom      = 0,
    UserMacAccel = 1,
    UserError    = 2
  } user_demux_outputs_e;

  // Address map rules
  localparam croc_pkg::addr_map_rule_t [NumDemuxSbrRules-1:0] user_addr_map = '{
    '{ idx: UserRom,
       start_addr: UserRomAddrOffset,
       end_addr:   UserRomAddrOffset + UserRomAddrRange },

    '{ idx: UserMacAccel,
       start_addr: MacAccelAddrOffset,
       end_addr:   MacAccelAddrOffset + MacAccelAddrRange }
  };

endpackage
