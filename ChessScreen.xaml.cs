using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;
using System.Diagnostics;


namespace Demo
{
    /// <summary>
    /// Interaction logic for ChessScreen.xaml
    /// </summary>
    public partial class ChessScreen : Window
    {
        Process prolog;
        private Button[,] chessBoard = new Button[8, 8];
        private Button selectedButton = null;
        private string prologMove = "";
        string[,] boardPositions = new string[8, 8]
        {
            { "a1", "b1", "c1", "d1", "e1", "f1", "g1", "h1" }, // Row 1 (White back rank)
            { "a2", "b2", "c2", "d2", "e2", "f2", "g2", "h2" }, // Row 2 (White pawns)
            { "a3", "b3", "c3", "d3", "e3", "f3", "g3", "h3" }, // Row 3
            { "a4", "b4", "c4", "d4", "e4", "f4", "g4", "h4" }, // Row 4
            { "a5", "b5", "c5", "d5", "e5", "f5", "g5", "h5" }, // Row 5
            { "a6", "b6", "c6", "d6", "e6", "f6", "g6", "h6" }, // Row 6
            { "a7", "b7", "c7", "d7", "e7", "f7", "g7", "h7" }, // Row 7 (Black pawns)
            { "a8", "b8", "c8", "d8", "e8", "f8", "g8", "h8" }  // Row 8 (Black back rank)
        };

        private Dictionary<string, string> pieces = new Dictionary<string, string>()
        {
            // White pieces
            {"a1", "R"}, {"b1", "N"}, {"c1", "B"}, {"d1", "Q"},
            {"e1", "K"}, {"f1", "B"}, {"g1", "N"}, {"h1", "R"},
            {"a2", "P"}, {"b2", "P"}, {"c2", "P"}, {"d2", "P"},
            {"e2", "P"}, {"f2", "P"}, {"g2", "P"}, {"h2", "P"},

            // Black pieces
            {"a8", "R'"}, {"b8", "N'"}, {"c8", "B'"}, {"d8", "Q'"},
            {"e8", "K'"}, {"f8", "B'"}, {"g8", "N'"}, {"h8", "R'"},
            {"a7", "P'"}, {"b7", "P'"}, {"c7", "P'"}, {"d7", "P'"},
            {"e7", "P'"}, {"f7", "P'"}, {"g7", "P'"}, {"h7", "P'"}
        };

        public ChessScreen()
        {
            InitializeComponent();
            CreateChessBoard();
            CreatePrologProcess();
        }

        private string GetButtonPosition(Button button)
        {
            int r = Grid.GetRow(button);
            int c = Grid.GetColumn(button);
            return boardPositions[r, c];
        }

        private void CreateChessBoard()
        {
            for (int row = 0; row < 8; row++)
            {
                for (int col = 0; col < 8; col++)
                {
                    
                    Button button = new Button
                    {
                        FontSize = 24,
                        FontWeight = FontWeights.Bold
                    };

                    // Set the background color (alternating pattern)
                    button.Background = (row + col) % 2 == 0 ? Brushes.White : Brushes.Gray;

                    // Set the piece if it exists
                    char c = (char)('a' + col);
                    string position = $"{c}{row + 1}";
                    if (pieces.ContainsKey(position))
                    {
                        button.Content = pieces[position];
                    }

                    button.Click += ChessSquare_Click;
                    Grid.SetRow(button, row);
                    Grid.SetColumn(button, col);
                    chessBoard[row, col] = button;
                    ((Grid)Content).Children.Add(button);
                }
            }
        }

        private void ChessSquare_Click(object sender, RoutedEventArgs e)
        {
            Button clickedButton = (Button)sender;
            
            // If no piece is selected and clicked button has a piece
            if (selectedButton == null && clickedButton.Content != null)
            {
                selectedButton = clickedButton;
                clickedButton.Background = Brushes.Yellow; // Highlight selected piece
                prologMove = GetButtonPosition(clickedButton);
            }
            // If a piece is selected and clicked on an empty square
            else if (selectedButton != null && clickedButton != selectedButton)
            {
                // Move the piece
                clickedButton.Content = selectedButton.Content;
                selectedButton.Content = null;

                // Reset the background colors
                ResetSquareColor(selectedButton);
                selectedButton = null;
                prologMove += GetButtonPosition(clickedButton) + '.';
                // Call Prolog with the move
                PrologQuery(prologMove);
                prologMove = "";
            }
            // Deselect the current piece
            else if (selectedButton == clickedButton)
            {
                ResetSquareColor(selectedButton);
                selectedButton = null;
                prologMove = "";
            }
        }

        private void ResetSquareColor(Button button)
        {
            int row = Grid.GetRow(button);
            int col = Grid.GetColumn(button);
            button.Background = (row + col) % 2 == 0 ? Brushes.White : Brushes.Gray;
        }

        public void CreatePrologProcess()
        {
            // Use relative path
            //string prologPath = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Prolog-chess-game-master", "chess.pl");

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

            prolog = new Process { StartInfo = psi };
            prolog.Start();

            var writer = prolog.StandardInput;
            var reader = prolog.StandardOutput;

            // Load your file
            writer.WriteLine("[chess]."); // assumes chess.pl in working dir
            writer.Flush();

            // Send a query
            writer.WriteLine("run.");
            writer.Flush();
        }

        void PrologQuery(string input)
        {
            var writer = prolog.StandardInput;
            var reader = prolog.StandardOutput;

            writer.WriteLine(input);
            writer.Flush();

            // Read the response
            string result = "";
            
            while (true)
            {
                string? line = reader.ReadLine();
                if (line == "START")
                {
                    result = reader.ReadLine();
                    while ((line = reader.ReadLine()) != "END") ;
                    break;
                }
            }

            // process the result
            string[] move = { result.Substring(0, 2), result.Substring(2) };

            // Extract coordinates from move[0] (e.g., "a2") and move[1] (e.g., "a4")
            int fromRow = move[0][1] - '1';
            int fromCol = move[0][0] - 'a';

            int toRow = move[1][1] - '1';
            int toCol = move[1][0] - 'a';

            // Access buttons from your chessBoard array
            Button from = chessBoard[fromRow, fromCol];
            Button to = chessBoard[toRow, toCol];
            // Move the piece
            to.Content = from.Content;
            from.Content = null;

            return;
        }
        protected override void OnClosed(EventArgs e)
        {
            base.OnClosed(e);
            prolog.Kill();
        }
    }
}
