using ChessLogic;
using ChessLogic.GameStates;
using ChessLogic.GameStates.GameState;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Threading;
using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;
using System.Windows.Threading;

namespace ChessUI
{
    /// <summary>
    /// Interaction logic for GameUserControl.xaml
    /// </summary>
    public partial class GameUserControl : UserControl
    {
        private readonly Image[,] pieceImages = new Image[8, 8];
        private readonly Rectangle[,] highlights = new Rectangle[8, 8];
        private readonly Canvas[,] posMoved = new Canvas[8, 8];
        private Dictionary<Position, Move> moveCache = new Dictionary<Position, Move>();
        public GameState gameState { get; set; }
        private Position selectedPos = null;
        private DispatcherTimer redTimer;
        private DispatcherTimer blackTimer;
        private bool isRedTurn = true;
        private Brush redBrush = new SolidColorBrush(Colors.Red);
        private Brush blackBrush = new SolidColorBrush(Colors.Black);
        private CancellationTokenSource cts = new CancellationTokenSource();
        private Stack<Tuple<Move, Piece>> moveList;
        private bool isReview = false;
        
        public GameUserControl(Player color, int timeLimit, bool isAI, int difficult = 1)
        {
            InitializeComponent();
            InitializeBoard();
            if (isAI == true) gameState = new GameStateAI(color, Board.Initial(), difficult, timeLimit);
            else gameState = new GameState2P(Player.White, Board.Initial(), timeLimit);
            ShowGameInformation(difficult);
            DrawBoard(gameState.Board);
            if (color == Player.Black && isAI == true) isRedTurn = false;
            if (timeLimit != 0)
            {
                InitializeTimer();
                SwitchTurn();
            }
            if (gameState is GameStateAI && color == Player.Black)
            {
                StartAIMoveWithDelay();
            }
        }
        //public GameUserControl(GameStateForLoad gameStateForLoad)
        //{
        //    InitializeComponent();
        //    InitializeBoard();
        //    if (gameStateForLoad.GameType == "GameStateAI") gameState = new GameStateAI(gameStateForLoad);
        //    else gameState = new GameState2P(gameStateForLoad);
        //    ShowGameInformation(gameStateForLoad.depth);
        //    DrawBoard(gameState.Board);
        //    foreach (var piece in gameState.CapturedRedPiece) DrawCapturedGrid(piece);
        //    foreach (var piece in gameState.CapturedBlackPiece) DrawCapturedGrid(piece);
        //    if (gameState.Moved.Any()) ShowPrevMove(gameState.Moved.First().Item1);
        //    if (gameState.timeRemainingBlack != 0)
        //    {
        //        InitializeTimer();
        //        SwitchTurn();
        //    }
        //}
        private void InitializeTimer()
        {
            int minutes = gameState.timeRemainingRed / 60;
            int seconds = gameState.timeRemainingRed % 60;
            redClock.Text = $"{minutes:D2}:{seconds:D2}";
            blackClock.Text = $"{minutes:D2}:{seconds:D2}";

            redTimer = new DispatcherTimer();
            redTimer.Interval = TimeSpan.FromSeconds(1);
            redTimer.Tick += RedTimer_Tick;
            blackTimer = new DispatcherTimer();
            blackTimer.Interval = TimeSpan.FromSeconds(1);
            blackTimer.Tick += BlackTimer_Tick;
        }
        private void RedTimer_Tick(object sender, EventArgs e)
        {
            gameState.timeRemainingRed--;
            int minutes = gameState.timeRemainingRed / 60;
            int seconds = gameState.timeRemainingRed % 60;
            redClock.Text = $"{minutes:D2}:{seconds:D2}";
            if (gameState.timeRemainingRed <= 0)
            {
                StopTimer();
                HideHighlights();
                CellGrid.IsEnabled = false;
                cts.Cancel();
                gameState.TimeForfeit();
                RaiseGameOverEvent(gameState);
                return;
            }
            if (gameState.timeRemainingRed < 60)
            {
                redClock.Foreground = redBrush;
            }
        }
        private void BlackTimer_Tick(object sender, EventArgs e)
        {
            gameState.timeRemainingBlack--;
            int minutes = gameState.timeRemainingBlack / 60;
            int seconds = gameState.timeRemainingBlack % 60;
            blackClock.Text = $"{minutes:D2}:{seconds:D2}";
            if (gameState.timeRemainingBlack <= 0)
            {
                StopTimer();
                HideHighlights();
                CellGrid.IsEnabled = false;
                cts.Cancel();
                gameState.TimeForfeit();
                RaiseGameOverEvent(gameState);
                return;
            }
            if (gameState.timeRemainingBlack < 60)
            {
                blackClock.Foreground = redBrush;
            }
        }
        internal void StopTimer()
        {
            if (redTimer == null) return;
            redTimer.Stop();
            blackTimer.Stop();
        }
        internal void ContinueTimer()
        {
            if (redTimer == null) return;
            if (!gameState.IsGameOver())
            {
                if (isRedTurn)
                {
                    redTimer.Start();
                }
                else
                {
                    blackTimer.Start();
                }
            }
        }
        public void ResetTimer()
        {
            if (redTimer != null)
            {
                redTimer.Stop();
                redTimer.Tick -= RedTimer_Tick;
                redTimer = null;
            }
            if (blackTimer != null)
            {
                blackTimer.Stop();
                blackTimer.Tick -= BlackTimer_Tick;
                blackTimer = null;
            }
        }
        private void SwitchTurn()
        {
            redTimer.Stop();
            blackTimer.Stop();

            if (isRedTurn)
            {
                redTimer.Start();
            }
            else
            {
                blackTimer.Start();
            }
        }
        private void ShowGameInformation(int difficult)
        {
            switch (difficult)
            {
                case 2:
                    blackInfo.Text = "Máy (Độ khó: Dễ)";
                    break;
                case 3:
                    blackInfo.Text = "Máy (Độ khó: Thường)";
                    break;
                case 4:
                    blackInfo.Text = "Máy (Độ khó: Khó)";
                    break;
                case 1:
                    blackInfo.Text = "Người chơi 2";
                    break;
            }
            TurnTextBlock.Text = gameState.CurrentPlayer == Player.White ? "Trắng" : "Đen";
        }

        private async void StartAIMoveWithDelay()
        {
            UnableClick();
            await Task.Delay(500);
            if (gameState is GameStateAI AI)
            {
                await Task.Run(() => AI.AiMove(cts.Token), cts.Token);
                DrawBoard(gameState.Board);
                ShowPrevMove(gameState.Moved.First().Item1);
                Sound.PlayMoveSound();
            }
            AbleClick();
            isRedTurn = !isRedTurn;
            if (redTimer != null) SwitchTurn();
        }
        private void UnableClick()
        {
            CellGrid.IsHitTestVisible = false;
            PauseButton.IsEnabled = false;
            UndoButton.IsEnabled = false;
            SaveButton.IsEnabled = false;
        }
        private void AbleClick()
        {
            CellGrid.IsHitTestVisible = true;
            PauseButton.IsEnabled = true;
            UndoButton.IsEnabled = true;
            SaveButton.IsEnabled = true;
        }
        private async void HandleMove(Move move)
        {
            isRedTurn = !isRedTurn;
            if (redTimer != null) SwitchTurn();
            Sound.PlayMoveSound();
            UnableClick();
            if (gameState.Moved.Any()) HidePrevMove(gameState.Moved.First().Item1);
            gameState.MakeMove(move);
            DrawBoard(gameState.Board);
            ShowPrevMove(move);
            DrawCapturedGrid(gameState.CapturedPiece);
            WarningTextBlock.Text = gameState.Board.IsInCheck(gameState.CurrentPlayer) ? "Chiếu tướng!" : null;
            TurnTextBlock.Text = gameState.CurrentPlayer == Player.White ? "Trắng" : "Đen";
            await Dispatcher.InvokeAsync(() => { }, System.Windows.Threading.DispatcherPriority.Render);
            if (gameState is GameStateAI AI)
            {
                Move prevMove = gameState.Moved.First().Item1;
                await Task.Run(() => AI.AiMove(cts.Token), cts.Token);
                isRedTurn = !isRedTurn;
                if (redTimer != null) SwitchTurn();
                WarningTextBlock.Text = gameState.Board.IsInCheck(gameState.CurrentPlayer) ? "Chiếu tướng!" : null;
                TurnTextBlock.Text = gameState.CurrentPlayer == Player.White ? "Trắng" : "Đen";
                DrawCapturedGrid(gameState.CapturedPiece);
                DrawBoard(gameState.Board);
                HidePrevMove(prevMove);
                ShowPrevMove(gameState.Moved.First().Item1);
                Sound.PlayMoveSound();
            }

            AbleClick();
            if (gameState.IsGameOver())
            {
                UnableClick();
                moveList = new Stack<Tuple<Move, Piece>>(gameState.Moved.ToArray());
                HideHighlights();
                CellGrid.IsEnabled = false;
                if (redTimer != null) StopTimer();
                RaiseGameOverEvent(gameState);
            }
        }
        public void Review()
        {
            isReview = true;
            Board newBoard = Board.Initial();
            Player startPlayer;
            if (newBoard[moveList.Peek().Item1.FromPos].Color == Player.Black) startPlayer = Player.Black;
            else startPlayer = Player.White;
            HidePrevMove(gameState.Moved.Peek().Item1);
            gameState = new GameState2P(startPlayer, Board.Initial());
            TurnTextBlock.Text = (startPlayer == Player.Black) ? "Đen" : "Trắng";
            BlackCapturedGrid.Children.Clear();
            RedCapturedGrid.Children.Clear();
            redClock.Text = null;
            blackClock.Text = null;
            WarningTextBlock.Text = null;
            ResetTimer();
            DrawBoard(gameState.Board);
            AbleClick();
            SaveButton.IsEnabled = false;
            CellGrid.IsHitTestVisible = false;
            DoButton.Visibility = Visibility.Visible;
        }
        private void UndoButton_Click(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            if (gameState.Moved.Count != 0) HidePrevMove(gameState.Moved.First().Item1);
            OnToPositionSelected(selectedPos);
            if (isReview == true)
            {
                if (gameState.Moved.Count == 0) return;
                var move = gameState.Moved.Pop();
                Move doMove = new NormalMove(move.Item1.ToPos, move.Item1.FromPos);
                doMove.Execute(gameState.Board);
                gameState.Board[doMove.FromPos] = move.Item2;
                DrawBoard(gameState.Board);
                if (gameState.Moved.Count != 0)
                {
                    ShowPrevMove(gameState.Moved.First().Item1);
                }
                gameState.CapturedPiece = move.Item2;
                moveList.Push(move);
                gameState.CurrentPlayer = gameState.CurrentPlayer.Opponent();
                UndoCapturedGrid(gameState.CapturedPiece);
                TurnTextBlock.Text = gameState.CurrentPlayer == Player.White ? "Trắng" : "Đen";
                WarningTextBlock.Text = gameState.Board.IsInCheck(gameState.CurrentPlayer) ? "Chiếu tướng!" : null;
                gameState.noCapture.Pop();
            }
            else
            {
                gameState.UndoMove();
                DrawBoard(gameState.Board);
                if (gameState.Moved.Count != 0)
                {
                    ShowPrevMove(gameState.Moved.First().Item1);
                }
                WarningTextBlock.Text = gameState.Board.IsInCheck(gameState.CurrentPlayer) ? "Chiếu tướng!" : null;
                TurnTextBlock.Text = gameState.CurrentPlayer == Player.White ? "Trắng" : "Đen";

                UndoCapturedGrid(gameState.CapturedPiece);
                if (gameState is GameStateAI AI)
                    UndoAiCapturedGrid(AI.AiCapturedPiece);
                isRedTurn = gameState.CurrentPlayer == Player.White;
                if (redTimer != null) SwitchTurn();
            }
        }
        private void DoButton_Click(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            if (moveList.Count == 0) return;
            if (gameState.Moved.Count != 0) HidePrevMove(gameState.Moved.First().Item1);
            bool capture = moveList.Peek().Item1.Execute(gameState.Board);

            if (capture)
            {
                gameState.noCapture.Push(0);
            }
            else
            {
                if (gameState.noCapture.Count == 0) gameState.noCapture.Push(1);
                else gameState.noCapture.Push(gameState.noCapture.Peek() + 1);
            }
            gameState.Moved.Push(moveList.Pop());
            DrawBoard(gameState.Board);
            if (gameState.Moved.Count != 0)
            {
                ShowPrevMove(gameState.Moved.First().Item1);
            }
            DrawCapturedGrid(gameState.Moved.Peek().Item2);
            gameState.CurrentPlayer = gameState.CurrentPlayer.Opponent();
            WarningTextBlock.Text = gameState.Board.IsInCheck(gameState.CurrentPlayer) ? "Chiếu tướng!" : null;
            TurnTextBlock.Text = gameState.CurrentPlayer == Player.White ? "Trắng" : "Đen";
        }
        private void InitializeBoard()
        {
            for (int r = 0; r < 8; r++)
            {
                for (int c = 0; c < 8; c++)
                {
                    Image image = new Image();
                    pieceImages[r, c] = image;
                    PieceGrid.Children.Add(image);

                    Rectangle highlight = new Rectangle();
                    highlights[r, c] = highlight;
                    HighlightGrid.Children.Add(highlight);

                    Canvas canvas = new Canvas() { };
                    posMoved[r, c] = canvas;
                    PosMovedGrid.Children.Add(canvas);
                }
            }
        }

        public void DrawBoard(Board board)
        {
            for (int r = 0; r < 8; r++)
            {
                for (int c = 0; c < 8; c++)
                {
                    Piece piece = board[r, c];
                    pieceImages[r, c].Source = Images.GetImage(piece);
                }
            }
        }

        private void CacheMoves(IEnumerable<Move> moves)
        {
            moveCache.Clear();
            foreach (Move move in moves)
            {
                moveCache[move.ToPos] = move;
            }
        }

        private void ShowHighlights()
        {
            Color color = Color.FromArgb(150, 25, 255, 125);
            foreach (Position to in moveCache.Keys)
            {
                if (gameState.Board[to] != null)
                {
                    highlights[to.Row, to.Column].Fill = new SolidColorBrush(Color.FromArgb(150, 255, 0, 0));
                }
                else highlights[to.Row, to.Column].Fill = new SolidColorBrush(color);
            }
        }

        private void HideHighlights()
        {
            foreach (Position to in moveCache.Keys)
            {
                highlights[to.Row, to.Column].Fill = Brushes.Transparent;
            }
        }

        private void BoardGrid_MouseDown(object sender, MouseEventArgs e)
        {
            Point point = e.GetPosition(BoardGrid);
            Position pos = ToSquarePosition(point);

            if (selectedPos == null)
            {
                OnFromPositionSelected(pos);
            }
            else
            {
                OnToPositionSelected(pos);
            }
        }

        private Position ToSquarePosition(Point point)
        {
            double squareSize = BoardGrid.ActualWidth / 8;

            int row = (int)(point.Y / squareSize);
            int col = (int)(point.X / squareSize);

            //MessageBox.Show(row + " " + col);
            return new Position(row, col);
        }

        private void OnFromPositionSelected(Position pos)
        {
            IEnumerable<Move> moves = gameState.LegalMovesForPiece(pos);

            if (moves.Any())
            {
                selectedPos = pos;
                CacheMoves(moves);
                ShowHighlights();
            }
        }

        private void OnToPositionSelected(Position pos)
        {
            selectedPos = null;
            HideHighlights();

            if (pos == null) return;
            if (moveCache.TryGetValue(pos, out Move move))
            {
                HandleMove(move);
            }
        }
        private void DrawCapturedGrid(Piece piece)
        {
            if (piece == null) return;
            Image image = new Image();
            image.Source = Images.GetImage(piece);
            if (piece.Color == Player.White)
            {
                BlackCapturedGrid.Children.Add(image);
            }
            else
            {
                RedCapturedGrid.Children.Add(image);
            }
        }
        private void UndoCapturedGrid(Piece piece)
        {
            if (piece == null) return;
            if (gameState.CurrentPlayer == Player.Black)
            {
                int count = BlackCapturedGrid.Children.Count;
                if (count > 0)
                    BlackCapturedGrid.Children.RemoveAt(count - 1);
            }
            else
            {
                int count = RedCapturedGrid.Children.Count;
                if (count > 0)
                    RedCapturedGrid.Children.RemoveAt(count - 1);
            }
        }
        private void UndoAiCapturedGrid(Piece piece)
        {
            if (piece == null) return;
            int count = BlackCapturedGrid.Children.Count;
            if (count > 0)
                BlackCapturedGrid.Children.RemoveAt(count - 1);
        }
        private void DrawNewPos(Canvas canvas, int row, int col)
        {
            SolidColorBrush solidColorBrush = (gameState.Board[row, col].Color == Player.Black) ? Brushes.DarkBlue : Brushes.Red;
            Line topLeftArrow = new Line
            {
                X1 = 5,
                Y1 = 0,
                X2 = 25,
                Y2 = 0,
                Stroke = solidColorBrush,
                StrokeThickness = 2
            };
            canvas.Children.Add(topLeftArrow);
            Line sideTopLeftArrow = new Line
            {
                X1 = 5,
                Y1 = 0,
                X2 = 5,
                Y2 = 20,
                Stroke = solidColorBrush,
                StrokeThickness = 2
            };
            canvas.Children.Add(sideTopLeftArrow);
            Line topRightArrow = new Line
            {
                X1 = 55,
                Y1 = 0,
                X2 = 75,
                Y2 = 0,
                Stroke = solidColorBrush,
                StrokeThickness = 2
            };
            canvas.Children.Add(topRightArrow);
            Line sideTopRightArrow = new Line
            {
                X1 = 75,
                Y1 = 0,
                X2 = 75,
                Y2 = 20,
                Stroke = solidColorBrush,
                StrokeThickness = 2
            };
            canvas.Children.Add(sideTopRightArrow);
            Line bottomLeftArrow = new Line
            {
                X1 = 5,
                Y1 = 70,
                X2 = 25,
                Y2 = 70,
                Stroke = solidColorBrush,
                StrokeThickness = 2
            };
            canvas.Children.Add(bottomLeftArrow);
            Line sideBotLeftArrow = new Line
            {
                X1 = 5,
                Y1 = 70,
                X2 = 5,
                Y2 = 50,
                Stroke = solidColorBrush,
                StrokeThickness = 2
            };
            canvas.Children.Add(sideBotLeftArrow);
            Line bottomRightArrow = new Line
            {
                X1 = 55,
                Y1 = 70,
                X2 = 75,
                Y2 = 70,
                Stroke = solidColorBrush,
                StrokeThickness = 2
            };
            canvas.Children.Add(bottomRightArrow);
            Line sideBotRightArrow = new Line
            {
                X1 = 75,
                Y1 = 70,
                X2 = 75,
                Y2 = 50,
                Stroke = solidColorBrush,
                StrokeThickness = 2
            };
            canvas.Children.Add(sideBotRightArrow);
        }
        private void DrawOldPos(Canvas canvas, int row, int col)
        {
            SolidColorBrush solidColorBrush = (gameState.Board[row, col].Color == Player.Black) ? Brushes.DarkBlue : Brushes.Red;
            Line topLeftArrow = new Line
            {
                X1 = 20,
                Y1 = 15,
                X2 = 30,
                Y2 = 15,
                Stroke = solidColorBrush,
                StrokeThickness = 2
            };
            canvas.Children.Add(topLeftArrow);
            Line sideTopLeftArrow = new Line
            {
                X1 = 20,
                Y1 = 15,
                X2 = 20,
                Y2 = 25,
                Stroke = solidColorBrush,
                StrokeThickness = 2
            };
            canvas.Children.Add(sideTopLeftArrow);
            Line topRightArrow = new Line
            {
                X1 = 48,
                Y1 = 15,
                X2 = 58,
                Y2 = 15,
                Stroke = solidColorBrush,
                StrokeThickness = 2
            };
            canvas.Children.Add(topRightArrow);
            Line sideTopRightArrow = new Line
            {
                X1 = 58,
                Y1 = 15,
                X2 = 58,
                Y2 = 25,
                Stroke = solidColorBrush,
                StrokeThickness = 2
            };
            canvas.Children.Add(sideTopRightArrow);
            Line bottomLeftArrow = new Line
            {
                X1 = 20,
                Y1 = 53,
                X2 = 30,
                Y2 = 53,
                Stroke = solidColorBrush,
                StrokeThickness = 2
            };
            canvas.Children.Add(bottomLeftArrow);
            Line sideBotLeftArrow = new Line
            {
                X1 = 20,
                Y1 = 53,
                X2 = 20,
                Y2 = 43,
                Stroke = solidColorBrush,
                StrokeThickness = 2
            };
            canvas.Children.Add(sideBotLeftArrow);
            Line bottomRightArrow = new Line
            {
                X1 = 58,
                Y1 = 53,
                X2 = 48,
                Y2 = 53,
                Stroke = solidColorBrush,
                StrokeThickness = 2
            };
            canvas.Children.Add(bottomRightArrow);
            Line sideBotRightArrow = new Line
            {
                X1 = 58,
                Y1 = 53,
                X2 = 58,
                Y2 = 43,
                Stroke = solidColorBrush,
                StrokeThickness = 2
            };
            canvas.Children.Add(sideBotRightArrow);
        }
        public void ShowPrevMove(Move move)
        {
            //DrawOldPos(posMoved[move.FromPos.Row, move.FromPos.Column], move.ToPos.Row, move.ToPos.Column);
            //DrawNewPos(posMoved[move.ToPos.Row, move.ToPos.Column], move.ToPos.Row, move.ToPos.Column);
        }
        public void HidePrevMove(Move move)
        {
            posMoved[move.FromPos.Row, move.FromPos.Column].Children.Clear();
            posMoved[move.ToPos.Row, move.ToPos.Column].Children.Clear();
        }
        #region event
        public event RoutedEventHandler PauseButtonClicked
        {
            add { AddHandler(PauseButtonClickedEvent, value); }
            remove { RemoveHandler(PauseButtonClickedEvent, value); }
        }
        public static readonly RoutedEvent PauseButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "PauseButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(GameUserControl)
        );
        private void PauseButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(PauseButtonClickedEvent));
        }
        public event RoutedEventHandler SaveButtonClicked
        {
            add { AddHandler(SaveButtonClickedEvent, value); }
            remove { RemoveHandler(SaveButtonClickedEvent, value); }
        }
        public static readonly RoutedEvent SaveButtonClickedEvent = EventManager.RegisterRoutedEvent(
             "SaveButtonClicked",
             RoutingStrategy.Bubble,
             typeof(RoutedEventHandler),
             typeof(GameUserControl)
        );
        private void SaveButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(SaveButtonClickedEvent));
        }

        public static readonly RoutedEvent CloseAppButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "CloseAppButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(GameUserControl)
        );
        public event RoutedEventHandler CloseAppButtonClicked
        {
            add { AddHandler(CloseAppButtonClickedEvent, value); }
            remove { RemoveHandler(CloseAppButtonClickedEvent, value); }
        }

        private void CloseAppButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(CloseAppButtonClickedEvent));
        }

        private void MinimizeAppButton_Click(object sender, RoutedEventArgs e)
        {
            Application.Current.MainWindow.WindowState = WindowState.Minimized;
        }

        private void MaximizeAppButton_Click(object sender, RoutedEventArgs e)
        {
            if (Application.Current.MainWindow.WindowState == WindowState.Maximized)
            {
                Application.Current.MainWindow.WindowState = WindowState.Normal;
            }
            else Application.Current.MainWindow.WindowState = WindowState.Maximized;
        }

        private void TitleBar_MouseDown(object sender, MouseButtonEventArgs e)
        {
            if (e.LeftButton == MouseButtonState.Pressed)
            {
                Application.Current.MainWindow.DragMove();
            }
        }


        public static readonly RoutedEvent GameOverEvent = EventManager.RegisterRoutedEvent(
        "GameOver", RoutingStrategy.Bubble, typeof(RoutedEventHandler), typeof(GameUserControl));

        public event RoutedEventHandler GameOver
        {
            add { AddHandler(GameOverEvent, value); }
            remove { RemoveHandler(GameOverEvent, value); }
        }

        protected void RaiseGameOverEvent(GameState gameState)
        {
            RoutedEventArgs args = new RoutedPropertyChangedEventArgs<GameState>(null, gameState, GameOverEvent);
            RaiseEvent(args);
        }
        #endregion
    }
}
