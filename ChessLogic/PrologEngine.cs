using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SbsSW.SwiPlCs;

namespace ChessLogic
{
    public class PrologEngine
    {
        private static bool _isInitialized = false;

        public static void Initialize(string prologFile)
        {
            if (!_isInitialized)
            {
                // Khởi tạo Prolog engine
                PlEngine.Initialize(new string[] { "-q", "-f", "none" });
                _isInitialized = true;
            }

            // Load file Prolog
            if (!PlQuery.PlCall($"consult('{prologFile.Replace("\\", "/")}')"))
            {
                throw new Exception("Không thể load file Prolog.");
            }
        }

        public static List<string> QuerySingleVariable(string query, string variable)
        {
            var results = new List<string>();

            using (var q = new PlQuery(query))
            {
                foreach (PlQueryVariables vars in q.SolutionVariables)
                {
                    results.Add(vars[variable].ToString());
                }
            }

            return results;
        }

        public static void Cleanup()
        {
            if (_isInitialized)
            {
                PlEngine.PlCleanup();
                _isInitialized = false;
            }
        }
    }
}
