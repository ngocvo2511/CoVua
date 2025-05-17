using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using System.Diagnostics;
using System.Windows;

namespace Demo
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
        }
        private void Button_Click(object sender, RoutedEventArgs e)
        {
            string result = QueryProlog();
            MessageBox.Show("Prolog says: " + result);
        }

        public string QueryProlog()
        {
            // Example: call run(e2, Output)
            string prologPath = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "chess.pl");

            /*var psi = new ProcessStartInfo
            {
                Arguments = $"-s \"{prologPath}\" -g \"run('e4', Output), halt.\"",
                RedirectStandardOutput = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };*/

            var psi = new ProcessStartInfo
            {
                FileName = @"D:\Program Files\swipl\bin\swipl.exe",
                RedirectStandardInput = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            var prolog = new Process { StartInfo = psi };
            prolog.Start();

            var writer = prolog.StandardInput;
            var reader = prolog.StandardOutput;

            // Load your file
            writer.WriteLine("[chess]."); // assumes chess.pl in working dir
            writer.Flush();

            // Send a query
            writer.WriteLine("run.");
            writer.Flush();
            // Read the response
            string? line;
            string result = "";

            while(true)
            {
                if((line = reader.ReadLine()) != "START") continue;
                while((line = reader.ReadLine()) != "END")
                    MessageBox.Show(line,"Result");
                break;
            }
            // Keep it running and continue communicating...

            // Close when done
            writer.WriteLine("halt.");
            writer.Flush();
            prolog.WaitForExit();
            return "LOL";
        }
    }
}