using System;
using System.Threading;
using ROS2;
using std_msgs;
using sensor_msgs;
using example_interfaces;
using nav_msgs.srv;

namespace Examples
{
  /// <summary> A simple service client class to illustrate Ros2cs in action </summary>
  public class ROS2MMapServerClient
  {
    public static void Main(string[] args)
    {
      int n_calls = 0;
      Ros2cs.Init();
      INode node = Ros2cs.CreateNode("mapserver_client");
      Client<GetMap_Request, GetMap_Response> client = node.CreateClient<GetMap_Request, GetMap_Response>("map_server/map");

      Console.WriteLine("Starting caller - press ESC to stop.");
      while (!(Console.KeyAvailable && Console.ReadKey(true).Key == ConsoleKey.Escape))
      {
        if (client.IsServiceAvailable())
        {
          // GetMap_Response res = client.Call(new GetMap_Request()); // Call() never returns, but using CallAsync works...
          var task = client.CallAsync(new GetMap_Request());
          while (!task.IsCompleted)
          {
            Ros2cs.SpinOnce(node, 0.1);
          }
          GetMap_Response res = task.Result;
          Console.WriteLine((++n_calls)+" Map: " + res.Map.Info.Width + "x" + res.Map.Info.Height);
        }
        Thread.Sleep(TimeSpan.FromSeconds(1));
      }

      Ros2cs.Shutdown();
    }
  }
}
