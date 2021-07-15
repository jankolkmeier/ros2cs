using System;
using ROS2;
using System.Collections.Generic;

namespace ROS2
{
  public static class Ros2cs
  {
    private static readonly Destructor destructor = new Destructor();
    private static readonly object mutex = new object();
    private static bool initialized = false;  // should be equivalent to rcl::ok() - investigate
    private static rcl_context_t global_context;  // a simplification, we only use global default context
    private static List<INode> nodes = new List<INode>(); // kept to shutdown everything in order

    public static void Init()
    {
      lock (mutex)
      {
        if (initialized)
        {
          return;
        }

        Utils.CheckReturnEnum(NativeRclInterface.rclcs_init(ref global_context));
        initialized = true;
      }
    }

    public static void Shutdown()
    {
      lock (mutex)
      {
        if (!initialized)
        {
          return;
        }
        initialized = false;

        Utils.CheckReturnEnum(NativeRcl.rcl_shutdown(ref global_context));
        Ros2csLogger.GetInstance().LogInfo("Ros2cs shutdown");

        foreach (var node in nodes)
        {
          node.Dispose();
        }
        nodes.Clear();
      }
    }

    public static bool Ok()
    {
      return initialized;
    }

    private sealed class Destructor
    {
      ~Destructor()
      {
        Ros2csLogger.GetInstance().LogInfo("Ros2cs destructor called");
        Ros2cs.Shutdown();
        NativeRcl.rcl_context_fini(ref global_context);
      }
    }

    // TODO - expose NodeOptions
    public static INode CreateNode(string nodeName)
    {
      lock (mutex)
      {
        if (!initialized)
        {
          Ros2csLogger.GetInstance().LogError("Ros2cs is not initialized, cannot create node");
          throw new NotInitializedException();
        }

        foreach (var node in nodes)
        {
          if (node.Name == nodeName)
          {
            throw new InvalidOperationException("Node with name " + nodeName + " already exists, cannot create");
          }
        }

        var new_node = new Node(nodeName, ref global_context);
        nodes.Add(new_node);
        return new_node;
      }
    }

    public static bool RemoveNode(INode node)
    {
      lock (mutex)
      {
        if (!initialized)
        {
          return false; // removal is handled with shutdown already
        }
        node.Dispose();
        return nodes.Remove(node);
      }
    }

    public static void Spin(INode node, double timeoutSec = 0.1)
    {
      var nodes = new List<INode>{ node };
      Spin(nodes, timeoutSec);
    }

    public static void Spin(List<INode> nodes, double timeoutSec = 0.1)
    {
      while (initialized)
      {
        SpinOnce(nodes, timeoutSec);
      }
    }

    public static void SpinOnce(INode node, double timeoutSec = 0.1)
    {
      var nodes = new List<INode>{ node };
      SpinOnce(nodes, timeoutSec);
    }

    private static bool warned_once = false;
    public static void SpinOnce(List<INode> nodes, double timeoutSec = 0.1)
    {
      lock (mutex)
      {  // Figure out how to minimize this lock
        if (!initialized)
        {
          return;
        }

        if (timeoutSec < 0.0001d)
        {
          timeoutSec = 0.0001d;

          if (!warned_once)
          {
            Ros2csLogger.GetInstance().LogWarning("Spin timeout too low. Changed to a minimum value of " + timeoutSec.ToString());
            warned_once = true;
          }
        }

        // TODO - This can be optimized so that we cache the list and invalidate only with changes
        var allSubscriptions = new List<ISubscriptionBase>();
        foreach (INode node_interface in nodes)
        {
          Node node = node_interface as Node;
          if (node == null)
            continue; //Rare situation in which we are disposing

          foreach(ISubscriptionBase subscription in node.Subscriptions)
          {
            if (subscription == null)
              continue; //Rare situation in which we are disposing

            allSubscriptions.Add(subscription);
          }
        }

        // TODO - investigate performance impact
        WaitSet.Wait(global_context, allSubscriptions, timeoutSec);

        // Sequential processing
        foreach (var subscription in allSubscriptions)
        {
          subscription.TakeMessage();
        }
      }
    }
  }
}
