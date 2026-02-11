# TartanRGBT Workspace

Top-level workspace for the TartanRGBT dataset effort - a ROS2-based data collection system for RGB-Thermal sensor fusion.

## Overview

This repository provides a Docker-based development environment for collecting and recording RGB-Thermal (RGBT) sensor data using ROS.

The TartanRGBT platform is the first open-source data collection platform with hardware-synchronized RGB-Thermal image acquisition, introduced in the paper ["AnyThermal: Towards Learning Universal Representations for Thermal Perception"](https://arxiv.org/abs/2602.06203). This platform enables the collection of diverse RGB-Thermal datasets across multiple environments (indoor, aerial, off-road, urban) for advancing thermal perception research.

To know more about our work please visit the project website: [https://anythermal.github.io/](https://anythermal.github.io/)

## Hardware Payload Specifications

The TartanRGBT platform is a handheld data collection rig housed in a custom 3D-printed enclosure with ergonomic handles for ease of use. The payload captures synchronized stereo RGB and stereo thermal.

## Hardware Assembly 

Please refer to the [Hardware Assembly Guide](https://docs.google.com/document/d/1X5Av5y16SZzcaHOHzIiit1tz_KwJjkek2Er0iPeW7_g/edit?tab=t.0#heading=h.swwwpt7pk089) for detailed instructions on assembling the TartanRGBT payload, including BOM, component specifications, and 3D printing files for the enclosure.

### Core Components

1. **Compute Module**: NVIDIA Jetson AGX Orin Developer Kit (64GB)
   - Onboard processing for all sensor streams
   - ROS workspace execution
   - Real-time data synchronization

2. **RGB Cameras**: ZED X Stereo Camera
   - Factory-synchronized stereo RGB pair
   - Integrated IMU
   - Connects via ZED Link Quad Capture Card
   - Acts as a master to drive hardware time synchronization with thermal cameras

3. **Thermal Cameras**: 2× Teledyne FLIR Boson 640+ LWIR Cameras
   - Resolution: 640 × 512 pixels
   - Lens: 4.9mm focal length, 95° horizontal field of view (HFoV)
   - Type: With-Shutter LWIR (Long-Wave Infrared)
   - Hardware-synchronized via trigger pulse from ZED Link Capture Card Quad
   - Thermal sensitivity: ≤20 mK - Industrial grade
   - Each camera equipped with copper heat sinks and active cooling fans

4. **Power System**: Makita 18V LXT® Lithium-Ion 4.0Ah Battery
   - Portable power for extended field operation
   - Integrated power switch

5. **User Interface**:
   - Wi-Fi antennae for remote access
   - Recording trigger button (GPIO-based)
   - Slits on the 3D printed casing to easily access ORIN ports for connectivity

### Hardware Synchronization

All four cameras (2 RGB + 2 thermal) are hardware-synchronized at 30Hz:
- **RGB stereo pair**: Factory time-synced by ZED X camera
- **Thermal stereo pair**: Synchronized via trigger pulse from ZED Link Capture Card Quad
- **Cross-modal sync**: RGB and thermal cameras synchronized through hardware trigger system

This hardware synchronization ensures precise temporal alignment between all sensor modalities, critical for accurate sensor fusion and dataset quality.

### Thermal Management

The enclosure design includes:
- Copper heat sinks surrounding each thermal camera body
- 5V, 30mm blower fans for active cooling
- Air vents to ensure airflow around the onboard computer
- Maintains stable thermal camera operation during extended data collection sessions

## Prerequisites

- NVIDIA Jetson device (tested with L4T R36.4.4 on Jetson AGX Orin)
- Docker and Docker Compose installed
- ZED SDK 5.0.0 compatible camera
- GPIO-enabled button for recording control (optional but highly recommended for streamlined data collection)

## Quick Start

### 1. Build the Docker Image

Navigate to the docker directory and build the image:

```bash
cd docker
./jetson_build_dockerfile_from_sdk_and_l4T_version.sh l4t-r36.4.0 zedsdk-5.0.0
```

This script builds a Docker image with:
- NVIDIA L4T R36.4.0 base
- ZED SDK 5.0.0
- ROS workspace with required packages

### 2. Start the Container

Use Docker Compose to start the containerized environment:

```bash
docker compose up -d
```

### 3. Attach to the Container

Execute into the running container:

```bash
docker exec -it tartan_rgbt bash
```

## System Operation

### Sensor Startup

**Important:** The sensors require approximately **3 minutes** to fully initialize after container startup. Once contaner is started, it automatically boots up on each system bootup unless explictly stopped. This behaviour can be toggled by changing the `restart: unless-stopped` functionality in the `docker/docker-compose.yaml` file. 

Wait for sensor initialization to complete before attempting to start recording. You can monitor the initialization process in the tmux session.

### Sensor Monitoring

The tmux session provides real-time monitoring of sensor status and data streams. You can view:
- RGB and thermal image streams
- Real time frequency of each sensor stream

Use our `rviz/payload.rviz` with `rviz2`.

The publishing rate of each camera can be monitored on the following 
- RGB camera topics: `/health/zed/frequency`
- Thermal camera topics: `/health/thermal_left/frequency` and `/health/thermal_right/frequency`

### Recording Data

Recording can be initiated using a GPIO button connected to your Jetson device. The button interface provides a physical trigger for starting/stopping data collection.

**Recording workflow:**
1. Wait 3 minutes for sensor initialization
2. Press the GPIO button to start recording
3. Press again to stop recording
4. Recorded data is saved to the `/logging` directory. Make sure the `/logging` directory exists and is writable by the container.

## Development Environment

The system uses tmux for session management with multiple panes for different components. The tmux configuration is defined in `docker/tmux_config.yaml` and automatically launches on container startup.

### Tmux Layout

The workspace is organized into multiple tmux windows/panes for:
- Sensor nodes (ZED camera, thermal camera)
- Camera publishing rate monitoring
- Recording control

To navigate the tmux session:
- `Ctrl+b` then `[` - Enter scroll mode
- `Ctrl+b` then `w` - List windows
- `Ctrl+b` then arrow keys - Navigate between panes

## Project Structure

```
tartan_rgbt_ws/
├── docker/              # Docker build scripts and configurations
│   ├── tmux_config.yaml # Tmux session configuration (auto-launched at startup)
│   └── jetson_build_dockerfile_from_sdk_and_l4T_version.sh
├── rosbag/              # Recorded ROS bag files output directory
├── rviz/                # RViz visualization configurations
├── src/                 # ROS workspace source packages
└── README.md
```

## Configuration Files

### tmux_config.yaml

The `docker/tmux_config.yaml` file defines the development environment layout. It is automatically loaded when the container starts, setting up:
- ROS environment variables
- Sensor launch files
- Monitoring tools
- Recording interface

You can customize this file to adjust the workspace layout and startup commands.

## Data Output

Recorded ROS bags are stored in the `rosbag/` directory with timestamps. Each recording session creates a new bag file containing:
- **Stereo RGB images** from ZED X camera (factory-synchronized)
- **Stereo thermal images** from dual FLIR Boson 640+ cameras (hardware-synchronized)
- **IMU data** from ZED X camera
- **Camera calibration information** for both RGB and thermal cameras
- **Sensor timestamps** with hardware synchronization metadata
- **Thermal FFC (Flat Field Correction) status** flags

### Dataset Format

The TartanRGBT dataset consists of synchronized, registered RGB-thermal pairs sampled at configurable rates:
- **Default collection**: 30Hz hardware-synchronized capture
- **Dataset release**: 1Hz sampled pairs for non-redundant training data
- **ROS bag format**: Full sensor streams at native capture rates for flexible post-processing

All data includes stereo RGB, stereo thermal, IMU, and thermal camera status information, enabling research in:
- Cross-modal place recognition
- Thermal segmentation
- Monocular depth estimation from thermal
- RGB-Thermal sensor fusion
- Multi-environment perception (indoor, urban, off-road, aerial)

## Research Context

This data collection platform supports the **AnyThermal** project, which introduces a universal thermal perception backbone for diverse environments and tasks. The platform enables collection of the **TartanRGBT dataset** - a balanced collection of 16,943 synchronized RGB-thermal pairs spanning:

- **Urban environments**: Driving scenarios with varied lighting and weather
- **Indoor environments**: Buildings with diverse thermal signatures  
- **Off-road environments**: Natural terrain with vegetation and obstacles
- **Aerial environments**: Elevated perspectives for mapping and surveillance

### Applications

Data collected with this platform has been used for:
- Training task-agnostic thermal feature extractors (AnyThermal backbone)
- Cross-modal place recognition (achieving 36% improvement over baselines)
- Thermal semantic segmentation
- Monocular depth estimation from thermal imagery
- Knowledge distillation from RGB foundation models (DINOv2) to thermal domain

### Citation

If you use this platform or the TartanRGBT dataset in your research please consider giveing us a star on this repo and also please cite our work:

```bibtex
@misc{maheshwari2026anythermallearninguniversalrepresentations,
      title={AnyThermal: Towards Learning Universal Representations for Thermal Perception}, 
      author={Parv Maheshwari and Jay Karhade and Yogesh Chawla and Isaiah Adu and Florian Heisen and Andrew Porco and Andrew Jong and Yifei Liu and Santosh Pitla and Sebastian Scherer and Wenshan Wang},
      year={2026},
      eprint={2602.06203},
      archivePrefix={arXiv},
      primaryClass={cs.CV},
      url={https://arxiv.org/abs/2602.06203}, 
}
```

**Paper**: [AnyThermal: Towards Learning Universal Representations for Thermal Perception](https://arxiv.org/abs/2602.06203)  
**Project Website**: [https://anythermal.github.io/](https://anythermal.github.io/)

## License

This project is licensed under the BSD-3-Clause-Clear License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## Acknowledgments

This platform is part of the TartanRGBT dataset effort for advancing RGB-Thermal sensor fusion research. The handheld rig design prioritizes portability, ease of use, and hardware synchronization to enable diverse data collection across multiple environments.

**Key Features**:
- First open-source platform with hardware-synchronized RGB-Thermal stereo acquisition
- Custom 3D-printed enclosure with thermal management
- Portable battery-powered operation for field deployment
- GPIO-triggered recording for streamlined data collection workflows

## Contact

For questions or support, please open an issue on the GitHub repository.
