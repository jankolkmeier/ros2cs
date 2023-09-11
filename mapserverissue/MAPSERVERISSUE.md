# MAPSERVERISSUE

To reproduce, first start a map server. By default map.yaml is configured to load a 512x512 map.
```ros2 run nav2_map_server map_server --ros-args -p yaml_filename:=/path/to/ros2cs/mapserverissue/map.yaml```

Since map_server is a lifecycle node, you also need to run this in a separate terminal once after starting the map_server:
```ros2 run nav2_util lifecycle_bringup map_server```

Build this branch of `ros2cs`, source it and start the test client:
```ros2 run ros2cs_examples ros2cs_mapserverclient```
