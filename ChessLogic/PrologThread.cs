using System;
using System.Collections.Concurrent;
using System.Threading;
using System.Threading.Tasks;

namespace ChessLogic
{
    public class PrologRequest
    {
        public Func<object> Work { get; set; }
        public TaskCompletionSource<object> Tcs { get; set; }
    }

    public class PrologThread
    {
        private static PrologThread _instance;
        private readonly BlockingCollection<PrologRequest> _queue = new BlockingCollection<PrologRequest>();
        private Thread _thread;

        private PrologThread()
        {
            _thread = new Thread(Run) { IsBackground = true };
            _thread.Start();
        }

        public static PrologThread Instance => _instance ?? (_instance = new PrologThread());

        public Task<T> Enqueue<T>(Func<T> work)
        {
            var tcs = new TaskCompletionSource<object>();
            _queue.Add(new PrologRequest
            {
                Work = () => work(),
                Tcs = tcs
            });
            return tcs.Task.ContinueWith(t => (T)t.Result);
        }

        private void Run()
        {
            foreach (var req in _queue.GetConsumingEnumerable())
            {
                try
                {
                    var result = req.Work();
                    req.Tcs.SetResult(result);
                }
                catch (Exception ex)
                {
                    req.Tcs.SetException(ex);
                }
            }
        }
    }
} 