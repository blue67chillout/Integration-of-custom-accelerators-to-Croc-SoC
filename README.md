# Croc System-on-Chip

A simple SoC for education using PULP IPs. Croc includes all scripts necessary to produce a nearly finished chip in [IHPs open-source 130nm technology](https://github.com/IHP-GmbH/IHP-Open-PDK/tree/main).

As it is oriented towards education, it forgoes some configurability to increase readability of the RTL and scripts.

Croc is developed as part of the PULP project, a joint effort between ETH Zurich and the University of Bologna.

Croc was successfully taped out in Nov 2024. The chip is called [MLEM](http://asic.ee.ethz.ch/2024/MLEM.html), named after the sound Yoshi makes when eating a tasty fruit.
MLEM was designed and prepared for tapeout by ETHZ students as a bachelor project. The exact code and scripts used for the tapeout can be seen in the frozen [mlem-tapeout](https://github.com/pulp-platform/croc/tree/mlem-tapeout) branch.


**IMPORTANT: Update to 1.1 recommended.**  
Release 1.1 and newer includes a fix for the SRAMs where the `A_DLY` pin was tied low instead of high. The pin controls internal timings and the old version may create violations for some SRAMs.  


## Architecture

![Croc block diagram](doc/croc_arch.svg)

The SoC is composed of two main parts:
- The `croc_domain` containing a CVE2 core (a fork of Ibex), SRAM, an OBI crossbar and a few simple peripherals 
- The `user_domain` where students are invited to add their own designs or other open-source designs (peripherals, accelerators...)

The main interconnect is OBI, you can find [the spec online](https://github.com/openhwgroup/obi/blob/072d9173c1f2d79471d6f2a10eae59ee387d4c6f/OBI-v1.6.0.pdf). 

The various IPs of the SoC (UART, OBI, debug-module, timer...) come from other PULP repositories and are managed by [Bender](https://github.com/pulp-platform/bender).
To make it easier to browse and understand, only the currently used files are included in `rtl/<IP>`. You may want to explore the repositories of the respective IPs to find their documentation or additional functionality, the urls are in `Bender.yml`.

## Configuration

The main SoC configurations are in `rtl/croc_pkg.sv`:

| Parameter           | Default          | Function                                              |
|---------------------|------------------|-------------------------------------------------------|
| `HartId`            | `0`              | Core's Hart ID                                        |
| `PulpJtagIdCode`    | `32'hED9_C0C50`  | Debug module ID code                                  |
| `NumExternalIrqs`   | `4`              | Number of external interrupts into Croc domain        |
| `BankNumWords`      | `512`            | Number of 32bit words in a memory bank                |
| `NumSramBanks`      | `2`              | Number of memory banks                                |

The SRAMs are instantiated via a technology wrapper called `tc_sram_impl` (tc: tech_cells), the technology-independent implementation is in `rtl/tech_cells_generic/tc_sram_impl.sv`. A number of SRAM configurations are implemented using IHP130 SRAM memories in `ihp13/tc_sram_impl.sv`. If an unimplemented SRAM configuration is instantiated it will result in a `tc_sram_blackbox` module which can then be easily identified from the synthesis results.

## Bootmodes

Currently the only way to boot is via JTAG.

## Memory Map

If possible, the memory map should remain compatible with [Cheshire's memory map](https://pulp-platform.github.io/cheshire/um/arch/#memory-map).  
Further each new subordinate should occupy multiples of 4KB of the address space (`32'h0000_1000`).

The address map of the default configuration is as follows:

| Start Address   | Stop Address    | Description                                |
|-----------------|-----------------|--------------------------------------------|
| `32'h0000_0000` | `32'h0004_0000` | Debug module (JTAG)                        |
| `32'h0300_0000` | `32'h0300_1000` | SoC control/info registers                 |
| `32'h0300_2000` | `32'h0300_3000` | UART peripheral                            |
| `32'h0300_5000` | `32'h0300_6000` | GPIO peripheral                            |
| `32'h0300_A000` | `32'h0300_B000` | Timer peripheral                           |
| `32'h1000_0000` | `+SRAM_SIZE`    | Memory banks (SRAM)                        |
| `32'h2000_0000` | `32'h8000_0000` | Passthrough to user domain                 |
| `32'h2000_0000` | `32'h2000_1000` | reserved for string formatted user ROM*    |


*If people modify Croc we suggest they add a ROM at this address containing additional information 
like the names of the developers, a project link or similar. This can then be written out via UART.  
We ask people to format the ROM like a C string with zero termination and using ASCII encoding if feasible.  
The [MLEM user ROM](https://github.com/pulp-platform/croc/blob/mlem-tapeout/rtl/user_domain/user_rom.sv) may serve as a reference implementation.

## Flow
```mermaid
graph LR;
	Bender-->Yosys;
	Yosys-->OpenRoad;
	OpenRoad-->KLayout;
```
1. Bender provides a list of SystemVerilog files
2. Yosys parses, elaborates, optimizes and maps the design to the technology cells
3. The netlist, constraints and floorplan are loaded into OpenRoad for Place&Route
4. The design as def is read by klayout and the geometry of the cells and macros are merged

Currently, the final GDS is still missing the following things:
- metal density fill
- sealring
These can be added in KLayout, check the [IHP repository](https://github.com/IHP-GmbH/IHP-Open-PDK/tree/main) (possible the dev branch) for a reference script.

### Example Results
Cell/Module placement                      |  Routing
:-----------------------------------------:|:------------------------------------:
![Chip module view](doc/croc_modules.jpg)  |  ![Chip routed](doc/croc_routed.jpg)


### Local Installation

#### RISC-V Toolchain Install 

```sh
wget https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v14.2.0-2/xpack-riscv-none-elf-gcc-14.2.0-2-linux-x64.tar.gz
tar -xzf xpack-riscv-none-elf-gcc-14.2.0-2-linux-x64.tar.gz -C /opt

```
Just append the export of this newly installed riscv toolchain path later to your .[shell]rc file

```sh
echo 'PATH="/opt/xpack-riscv-none-elf-gcc-14.2.0-2/bin:$PATH"' >> .bashrc

or 

echo 'PATH="/opt/xpack-riscv-none-elf-gcc-14.2.0-2/bin:$PATH"' >> .zshrc
```

#### Yosys & Verilator Install

- Download an archive matching your OS from the releases page [https://github.com/YosysHQ/oss-cad-suite-build/releases/tag/2026-01-05].
- Extract the archive to a location of your choice (for Windows it is recommended that path does not contain spaces)
- On macOS to allow execution of quarantined files xattr -d com.apple.quarantine oss-cad-suite-darwin-x64-yyymmdd.tgz on downloaded file, or run: ./activate in extracted location once.
- Set the environment as described below

```sh
export PATH="<extracted_location>/oss-cad-suite/bin:$PATH"

# or

source <extracted_location>/oss-cad-suite/environment
```

#### OpenRoad Install

Download the relevant debian package from the release page [https://github.com/Precision-Innovations/OpenROAD/releases]

Then install it through apt

```sh

sudo apt install ./openroad_2.0_amd64-ubuntu20.04.deb

```
#### Bender Install

```sh
curl --proto '=https' --tlsv1.2 https://pulp-platform.github.io/bender/init -sSf | sh

```
This installs bender in your current directory, recommended to move the binary to /usr/bin


#### Docker (easy) 
There are two possible ways, the easiest way is to install docker and work in the docker container, you can follow the install guides on the [Docker Website](https://docs.docker.com/desktop/).  
You do not need to manually download the container image, this will be done when running the script.
If you do not have `git` installed on your system, you also need to install [Github Desktop](https://desktop.github.com/download/) and then clone this git repository.  

It is a good idea to grant non-root (`sudo`) users access to docker, this is decribed in the [Docker Article](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user).

Finally, you can navigate to this directory, open a terminal (PowerShell in Windows) and type:
```sh
# Linux only (starts and enters docker container in shell)
./start_linux.sh
# Linux/Mac (starts VNC server on localhost:5901)
./start_vnc.sh
# Windows (starts VNC server on localhost:5901)
./start_vnc.bat
```

If you use the VNC option, open a browser and type `localhost` in the address bar. 
This should connect you to the VNC server, the password is `abc123`, then test by right-clicking somewhere, starting the terminal and typing `ls`.  
You should see the files in this repository again.

Now you should be in an Ubuntu environment with all tools pre-installed for you.  
If something does not work, refer to the upstream [IIC-OSIC-Tools](https://github.com/iic-jku/IIC-OSIC-TOOLS/tree/main)


## Getting started
The SoC is fully functional as-is and a simple software example is provided for simulation.
To run the synthesis and place & route flow execute:
```sh
make checkout # fetched ihp130 pdk files
make yosys # generates flattened netlist from the source RTL files
make openroad # performs placement, routing and lef file generation
make klayout # streams gds from the generated lef file
```

To simulate you can use:
```sh
make verilator
```

The most important make targets are documented, you can list them with:
```sh
make help
```

### Building on Croc
To add your own design, we recommend creating a new directory under `rtl/` or put single source files (small designs) into `rtl/user_domain`, then go into `Bender.yml` and add the files in the indicated places.
This will make Bender aware of the files and any script it contains will contain your design as well.

Then re-generate the default synthesis file-list:
```sh
make yosys-flist
```

If you want to add an existing design and it already containts a `Bender.yml` in its repository, you can add it as a dependency in the `Bender.yml` and reading the guide below.

## Custom Accelerator Integration

### Overview

The Croc SoC is designed to allow easy integration of custom accelerators and peripherals into the **user domain**. This section documents the architecture, integration process, and testing methodology using the MAC (Multiply-Accumulate) accelerator as a reference example.

### Architecture

Custom accelerators are integrated into the **user domain** which operates in a separate address space (`0x2000_0000` to `0x8000_0000`) from the Croc domain. The integration follows these principles:

1. **OBI Protocol**: All user domain subordinates (accelerators/peripherals) communicate via the OBI (Open Bus Interface) protocol
2. **Address Demultiplexing**: The user domain uses an OBI demultiplexer to route requests to different subordinates based on address ranges
3. **Modular Design**: Each accelerator is a self-contained OBI subordinate module with its own address space (typically 4KB per accelerator)

### Integration Steps

#### 1. Create Accelerator RTL Module

Create your accelerator in `rtl/user_domain/your_accelerator.sv` with an OBI subordinate interface:

```systemverilog
module your_accelerator (
  input  logic        clk_i,
  input  logic        rst_ni,
  
  // OBI subordinate interface
  input  sbr_obi_req_t obi_req_i,
  output sbr_obi_rsp_t obi_rsp_o
);
  // Implementation...
endmodule
```

The OBI interface includes:
- **Request**: `obi_req_i.a` with address, data, and control signals
- **Response**: `obi_rsp_o.r` with read data and grant/valid handshakes

#### 2. Update `rtl/user_pkg.sv`

Define your accelerator's address space in the user package:

```systemverilog
// Number of subordinates (increment this)
localparam int unsigned NumUserDomainSubordinates = 3;  // ROM + MAC + Your Accelerator

// Define address map for your accelerator
localparam bit [31:0] YourAccelAddrOffset = UserBaseAddr + 32'h0000_2000;  // 0x2000_2000
localparam bit [31:0] YourAccelAddrRange  = 32'h0000_1000;  // 4 KB

// Add to user_demux_outputs_e enum
typedef enum int {
  UserRom        = 0,
  UserMacAccel   = 1,
  UserYourAccel  = 2,
  UserError      = 3
} user_demux_outputs_e;

// Add address rule
localparam croc_pkg::addr_map_rule_t [NumDemuxSbrRules-1:0] user_addr_map = '{
  // ... existing rules ...
  '{ idx: UserYourAccel,
     start_addr: YourAccelAddrOffset,
     end_addr:   YourAccelAddrOffset + YourAccelAddrRange }
};
```

#### 3. Instantiate in `rtl/user_domain.sv`

Add signal declarations and module instantiation:

```systemverilog
// Declare OBI buses for your accelerator
sbr_obi_req_t user_your_accel_obi_req;
sbr_obi_rsp_t user_your_accel_obi_rsp;

// Fanout from demux
assign user_your_accel_obi_req            = all_user_sbr_obi_req[UserYourAccel];
assign all_user_sbr_obi_rsp[UserYourAccel] = user_your_accel_obi_rsp;

// Instantiate your accelerator
your_accelerator i_your_accel (
  .clk_i,
  .rst_ni,
  .obi_req_i ( user_your_accel_obi_req ),
  .obi_rsp_o ( user_your_accel_obi_rsp )
);
```

#### 4. Update `Bender.yml`

Add your accelerator RTL file to the sources section:

```yaml
sources:
  - rtl/user_domain/your_accelerator.sv
```

### Memory Map Example

Each accelerator occupies 4KB of address space. Addresses are word-aligned (increments of 4 bytes):

| Address Offset | Register | Width | R/W | Purpose |
|---|---|---|---|---|
| `0x00` | operand_a | 32b | RW | First operand or control |
| `0x04` | operand_b | 32b | RW | Second operand or control |
| `0x08` | operand_c | 32b | RW | Third operand or control |
| `0x0C` | result | 32b | R | Computation result |
| `0x10` | status | 32b | R | Done flag / status |
| `0x14` | control | 32b | W | Start / trigger signal |

### Testing Your Accelerator

#### Hardware Test (C Software)

Create a test program in `sw/your_accel_test.c`:

You can find an example inside sw/mac_test.c

#### RTL Simulation

```bash
# Include your accelerator in simulation
make yosys-flist    # Regenerate file list
make verilator SW_HEX=sw/bin/your_test.hex     # Run simulation
```

### OBI Protocol Reference

The OBI subordinate interface requires proper handshaking:

- **Grant (gnt)**: Subordinate asserts to accept a request (typically `!rsp_pending`)
- **Request Valid (req)**: Manager asserts when presenting a valid request
- **Response Valid (rvalid)**: Subordinate asserts for one cycle with read response
- **Address (addr[31:0])**: Word-aligned address from manager
- **Write Enable (we)**: High for writes, low for reads
- **Write Data (wdata[31:0])**: Data to write
- **Read Data (rdata[31:0])**: Data returned for reads

### Common Register Patterns

**Compute-then-read pattern** (as used in MAC accelerator):
1. Write inputs to input registers
2. Write to control register to start computation
3. Poll status register for completion
4. Read result register when done

**Immediate response pattern** (for registers without computation):
- Respond to reads/writes within the same cycle

### Integration Checklist

- [ ] Create RTL module with OBI subordinate interface
- [ ] Define address range in `rtl/user_pkg.sv`
- [ ] Add enum entry to `user_demux_outputs_e`
- [ ] Add address rule to `user_addr_map`
- [ ] Add signal declarations in `rtl/user_domain.sv`
- [ ] Instantiate module in `rtl/user_domain.sv`
- [ ] Add RTL file to `Bender.yml` sources
- [ ] Create C test program in `sw/`
- [ ] Test with `make yosys-flist && make verilator`
- [ ] Run hardware test via UART

### Files to Modify

| File | Purpose |
|---|---|
| `rtl/user_domain/your_accelerator.sv` | Create new accelerator RTL |
| `rtl/user_pkg.sv` | Add address map definitions |
| `rtl/user_domain.sv` | Instantiate accelerator |
| `Bender.yml` | Add RTL files to sources |
| `sw/your_accel_test.c` | Create test program |

### Reference Implementation

The MAC accelerator (`rtl/user_domain/mac_accelerator.sv`) demonstrates a complete integration:
- OBI subordinate with request/response handling
- Register-based interface with address decoding
- Computation triggered by control register write
- Status polling pattern for synchronization

Refer to it as a template for your custom accelerators.

## Bender
The dependency manager [Bender](https://github.com/pulp-platform/bender) is used in most pulp-platform IPs.
Usually each dependency would be in a seperate repository, each with a `Bender.yml` file to describe where the RTL files are, how you can use this dependency and which additional dependency it has.
In the top level repository (like this SoC) you also have a `Bender.yml` file but you will commonly find a `Bender.lock` file. It contains the resolved tree of dependencies with specific commits for each. Whenever you run a command using Bender, this is the file it uses to figure out where things are.

Below is a small guide aimed at the usecase for this project. The Bender repo has a more extensive [Command Guide](https://github.com/pulp-platform/bender?tab=readme-ov-file#commands).

### Checkout
Using the command `bender checkout` Bender will check the lock file and download the specified commits from the repositories (usually into a hidden `.bender` directory). 

### Update
Running `bender update` on the other hand will resolve the entire tree again and re-generate the lock file (you usually have to resolve some version/revision conflicts if multiple things use the same dependency).

**Remember:** always test everything again if you generate a new `Bender.lock`, it is the same as modifying RTL.

### Local Versions
For this repository, we use a subcommand called `bendor vendor` together with the `vendor_package` section in `Bender.yml`.
`bendor vendor` can be used to Benderize arbitrary repositories with RTL in it. The dependencies are already 'checked out' into `rtl/<IP>`. Each file or directory from the repository is mapped to a local path in this repo.
Fixes and changes to each IPs `rtl/<IP>/Bender.yml` are managed by `bender vendor` in `rtl/patches`.

If you need to update a dependency or map another file you need to edit the coresponding `vendor_package` section in `Bender.yml` and then run `bender vendor init`. Then you might need to change `rtl/<IP>/Bender.yml` to list your new file in the sources. 
To save a fix/change as a patch, stage it in git and then run `bender vendor patch`. When prompted, add a commit message (this is used as the patches file name). Finally, commit both the patch file and the new `rtl/<IP>`.

**Note:** using `bender vendor` in this repository to change the local versions of the IPs requires an up-to-date version of Bender, specifically it needs to include [PR 179](https://github.com/pulp-platform/bender/pull/179).

### Targets
Another thing we use are targets (in the `Bender.yml`), together they build different views/contexts of your RTL. For example without defining any targets the technology independent cells/memories are used (in `rtl/tech_cells_generic/`) but if we use the target `ihp13` then the same modules contain a technology-specific implementation (in `ihp13/`). Similar contexts are built for different simulators and other things.

## License
Unless specified otherwise in the respective file headers, all code checked into this repository is made available under a permissive license. All hardware sources and tool scripts are licensed under the Solderpad Hardware License 0.51 (see `LICENSE.md`). All software sources are licensed under Apache 2.0.
