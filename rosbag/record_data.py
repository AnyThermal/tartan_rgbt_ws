#!/usr/bin/env python3

import subprocess
import yaml
import os
import sys
import signal
import argparse

break_bags = True

def load_topics(yaml_file):
    """Load topics from a YAML file."""
    if not os.path.exists(yaml_file):
        print(f"YAML file not found: {yaml_file}")
        sys.exit(1)

    with open(yaml_file, 'r') as file:
        data = yaml.safe_load(file)

    topics = data.get('topics', [])
    if not topics:
        print("No topics found in YAML under 'topics'")
        sys.exit(1)

    return topics

def record_rosbag(topics, storage="mcap"):
    global break_bags
    """Run ros2 bag record with the specified topics."""
    cmd = [
        "ros2", "bag", "record"]
    
    if storage =="mcap":
        cmd.extend(["-s", storage, "--storage-config-file", "mcap_qos_agx.yaml"])

    cmd.extend([
        "--max-cache-size", "5073741824"])

    if break_bags:
        cmd.extend(["--max-bag-size", "4000000000"])    # Split bag every ~4GB

    cmd.extend(topics)                           # Add the topic list

    print("Running command:")
    print(" ".join(cmd))

    # Start ros2 bag record as a subprocess
    process = subprocess.Popen(cmd)

    def signal_handler(sig, frame):
        print("\n[INFO] Caught Ctrl+C, stopping ros2 bag record...")
        process.send_signal(sig)  # Forward SIGINT to ros2 bag record

    # Handle Ctrl+C
    signal.signal(signal.SIGINT, signal_handler)

    try:
        process.wait()  # Wait for ros2 bag to finish
    except KeyboardInterrupt:
        print("[INFO] Waiting for ros2 bag record to flush cache and exit...")
        process.wait()

    print("[INFO] ros2 bag record has exited cleanly.")

def main():


    parser = argparse.ArgumentParser(description="Record ROS2 bag data")
    parser.add_argument("--yaml-file", default="topic_list.yaml", help="Path to YAML file")
    parser.add_argument("--single_bag", action="store_true", help="Do not break bags into multiple files")
    parser.add_argument("--storage", default="mcap", help="Storage backend (e.g., mcap or sqlite3)")

    args = parser.parse_args()
    global break_bags
    break_bags = not args.single_bag


    topics = load_topics(args.yaml_file)
    record_rosbag(topics, storage=args.storage)

if __name__ == "__main__":
    main()
