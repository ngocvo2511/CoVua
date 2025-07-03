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
using ChessUI.Menus;
using SbsSW.SwiPlCs;

namespace ChessUI
{
    /// <summary>
    /// Interaction logic for GameUserControl.xaml
    /// </summary>
    public partial class GameUserControl : UserControl
    {
        private readonly Image[,] pieceImages = new Image[8, 8];
        private readonly Rectangle[,] highlights = new Rectangle[8, 8];
        private readonly Rectangle[,] posMoved = new Rectangle[8, 8];
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
            if (color == Player.Black && isAI == true) isRedTurn = false;
            if (timeLimit != 0)
            {
                InitializeTimer();
                SwitchTurn();
            }
        }
        public static async Task<GameUserControl> Create(Player color, int timeLimit, bool isAI, int difficult = 1)
        {
            var control = new GameUserControl(color, timeLimit, isAI, difficult);
            string rootPath = System.IO.Path.GetFullPath(System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\..\.."));
            string prologPath = System.IO.Path.Combine(rootPath, "ChessLogic", "Prolog", "chess.pl");
            await PrologEngine.InitializeAsync(prologPath, isAI, color);
            control.gameState.Board = Board.FromPrologPosition(await PrologEngine.GetCurrentPositionAsync());
            control.DrawBoard(control.gameState.Board);
            if (control.gameState is GameStateAI && color == Player.Black)
            {
                var result = await PrologEngine.AiMoveAsync();
                if (result.HasValue)
                {
                    var (status, from, to) = result.Value;
                    control.gameState.MakeMove(new NormalMove(Position.IntToPosition(from), Position.IntToPosition(to)));
                    control.gameState.Board = Board.FromPrologPosition(await PrologEngine.GetCurrentPositionAsync());
                    control.isRedTurn = !control.isRedTurn;
                    if (control.redTimer != null) control.SwitchTurn();
                    control.WarningTextBlock.Text = status == "CHECK" ? "Chiếu tướng!" : null;
                    control.TurnTextBlock.Text = control.gameState.CurrentPlayer == Player.White ? "Trắng" : "Đen";
                    control.DrawCapturedGrid(control.gameState.CapturedPiece);
                    control.DrawBoard(control.gameState.Board);
                    control.ShowPrevMove(control.gameState.Moved.First().Item1);
                    Sound.PlayMoveSound();
                }
                else
                {
                    Console.WriteLine("Không thể thực hiện bot_move.");
                }
            }
            return control;
        }

        public GameUserControl(GameStateForLoad gameStateForLoad)
        {
            InitializeComponent();
            InitializeBoard();
        }
        public static async Task<GameUserControl> Create(GameStateForLoad gameStateForLoad)
        {
            var control = new GameUserControl(gameStateForLoad);
            string rootPath = System.IO.Path.GetFullPath(System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\..\.."));
            string prologPath = System.IO.Path.Combine(rootPath, "ChessLogic", "Prolog", "chess.pl");
            await PrologEngine.InitializeGameLoadAsync(prologPath, gameStateForLoad);
            Board board = Board.FromPrologPosition(await PrologEngine.GetCurrentPositionAsync());
            gameStateForLoad.Moved = PrologEngine.ParseHistory(gameStateForLoad.historyBoard);
            if (gameStateForLoad.GameType == "GameStateAI") control.gameState = new GameStateAI(gameStateForLoad, board);
            else control.gameState = new GameState2P(gameStateForLoad, board);
            control.ShowGameInformation(gameStateForLoad.depth);
            control.DrawBoard(control.gameState.Board);
            foreach (var piece in control.gameState.CapturedWhitePiece) control.DrawCapturedGrid(piece);
            foreach (var piece in control.gameState.CapturedBlackPiece) control.DrawCapturedGrid(piece);
            if (control.gameState.Moved.Any()) control.ShowPrevMove(control.gameState.Moved.First().Item1);
            if (control.gameState.timeRemainingBlack != 0)
            {
                control.InitializeTimer();
                control.SwitchTurn();
            }
            return control;
        }
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
                default:
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
        private async void HandleMove(Move move, PrologEngine.MakeMoveResult result)
        {
            isRedTurn = !isRedTurn;
            if (redTimer != null) SwitchTurn();
            Sound.PlayMoveSound();
            UnableClick();
            if (gameState.Moved.Any()) HidePrevMove(gameState.Moved.First().Item1);
            gameState.MakeMove(move);
            gameState.Board = Board.FromPrologPosition(await PrologEngine.GetCurrentPositionAsync());
            DrawBoard(gameState.Board);
            ShowPrevMove(move);
            DrawCapturedGrid(gameState.CapturedPiece);
            TurnTextBlock.Text = gameState.CurrentPlayer == Player.White ? "Trắng" : "Đen";

            // Kiểm tra trạng thái ván cờ sau khi đi
            string gameStatus = result.Status.ToUpper();
            WarningTextBlock.Text = gameStatus == "CHECK" ? "Chiếu tướng!" : null;

            if (gameStatus == "CHECKMATE" || gameStatus == "STALEMATE")
            {
                gameState.Result = Result.Win(gameState.CurrentPlayer.Opponent(), gameStatus == "CHECKMATE" ? EndReason.Checkmate : EndReason.Stalemate);
                UnableClick();
                moveList = new Stack<Tuple<Move, Piece>>(gameState.Moved.ToArray());
                HideHighlights();
                CellGrid.IsEnabled = false;
                if (redTimer != null) StopTimer();
                RaiseGameOverEvent(gameState);
            }
            else if (gameStatus == "THREEFOLDREPETITION")
            {
                gameState.Result = Result.Draw(EndReason.ThreefoldRepetition);
                UnableClick();
                moveList = new Stack<Tuple<Move, Piece>>(gameState.Moved.ToArray());
                HideHighlights();
                CellGrid.IsEnabled = false;
                if (redTimer != null) StopTimer();
                RaiseGameOverEvent(gameState);
            }
            else if (gameStatus == "FIFTYMOVERULE")
            {
                gameState.Result = Result.Draw(EndReason.FiftyMoveRule);
                UnableClick();
                moveList = new Stack<Tuple<Move, Piece>>(gameState.Moved.ToArray());
                HideHighlights();
                CellGrid.IsEnabled = false;
                if (redTimer != null) StopTimer();
                RaiseGameOverEvent(gameState);
            }

            await Dispatcher.InvokeAsync(() => { }, System.Windows.Threading.DispatcherPriority.Render);
            if (gameState is GameStateAI AI)
            {
                await Task.Delay(500); // Delay to simulate thinking time
                Move prevMove = gameState.Moved.First().Item1;
                var result1 = await PrologEngine.AiMoveAsync();
                if (result1.HasValue)
                {
                    var (status, from, to) = result1.Value;
                    gameState.MakeMove(new NormalMove(Position.IntToPosition(from), Position.IntToPosition(to)));
                    gameState.Board = Board.FromPrologPosition(await PrologEngine.GetCurrentPositionAsync());
                    isRedTurn = !isRedTurn;
                    if (redTimer != null) SwitchTurn();

                    WarningTextBlock.Text = status == "CHECK" ? "Chiếu tướng!" : null;
                    TurnTextBlock.Text = gameState.CurrentPlayer == Player.White ? "Trắng" : "Đen";
                    DrawCapturedGrid(gameState.CapturedPiece);
                    DrawBoard(gameState.Board);
                    HidePrevMove(prevMove);
                    ShowPrevMove(gameState.Moved.First().Item1);
                    Sound.PlayMoveSound();
                }
                else
                {
                    Console.WriteLine("Không thể thực hiện bot_move.");
                }
            }

            AbleClick();
            //if (gameState.IsGameOver())
            //{
            //    UnableClick();
            //    moveList = new Stack<Tuple<Move, Piece>>(gameState.Moved.ToArray());
            //    HideHighlights();
            //    CellGrid.IsEnabled = false;
            //    if (redTimer != null) StopTimer();
            //    RaiseGameOverEvent(gameState);
            //}
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
            WhiteCapturedGrid.Children.Clear();
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
        private async void UndoButton_Click(object sender, RoutedEventArgs e)
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
                //gameState.noCapture.Pop();
            }
            else
            {
                await PrologEngine.UndoAsync();
                if (gameState is GameStateAI gs)
                {
                    await PrologEngine.UndoAsync();
                }
                gameState.UndoMove();
                gameState.Board = Board.FromPrologPosition(await PrologEngine.GetCurrentPositionAsync());
                DrawBoard(gameState.Board);
                if (gameState.Moved.Count != 0)
                {
                    ShowPrevMove(gameState.Moved.First().Item1);
                }
                string status = PrologEngine.GetGameStatusAsync().Result;
                WarningTextBlock.Text = status == "CHECK" ? "Chiếu tướng!" : null;
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
                //gameState.noCapture.Push(0);
            }
            else
            {
                //if (gameState.noCapture.Count == 0) gameState.noCapture.Push(1);
                //else gameState.noCapture.Push(gameState.noCapture.Peek() + 1);
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

                    Rectangle pos = new Rectangle() { };
                    posMoved[r, c] = pos;
                    PosMovedGrid.Children.Add(pos);
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
                // Phân loại lại move: nếu là tốt đi chéo tới ô trống thì là EnPassant
                var from = move.FromPos;
                var to = move.ToPos;
                Piece piece = gameState.Board[from];
                Move realMove;
                if (piece != null && piece.Type == PieceType.Pawn && from.Column != to.Column && gameState.Board[to] == null)
                {
                    realMove = new EnPassant(from, to);
                }
                else
                {
                    realMove = new NormalMove(from, to);
                }
                moveCache[to] = realMove;
            }
        }

        private void ShowHighlights()
        {
            Color color = Color.FromArgb(150, 25, 255, 125);
            foreach (Position to in moveCache.Keys)
            {
                if (gameState.Board[to] != null)
                {
                    highlights[to.Row, to.Column].Fill = new SolidColorBrush(Color.FromArgb(225, 255, 0, 0));
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

            return new Position(row, col);
        }

        private async void OnFromPositionSelected(Position pos)
        {
            // Chuyển đổi tọa độ bàn cờ sang số 0-63
            int fromPos = (7 - pos.Row) * 8 + pos.Column;

            // Lấy các nước đi hợp lệ từ Prolog (async)
            List<Move> legalMoves = await PrologEngine.GetLegalMovesAsync(fromPos);

            if (legalMoves.Any())
            {
                selectedPos = pos;
                CacheMoves(legalMoves);
                ShowHighlights();
            }
        }

        private async void OnToPositionSelected(Position pos)
        {
            selectedPos = null;
            HideHighlights();

            if (pos == null) return;
            if (moveCache.TryGetValue(pos, out Move move))
            {
                // Chuyển đổi tọa độ bàn cờ sang số 0-63
                int fromPos = (7 - move.FromPos.Row) * 8 + move.FromPos.Column;
                int toPos = (7 - move.ToPos.Row) * 8 + move.ToPos.Column;

                // Thực hiện nước đi trong Prolog (async)
                var result = await PrologEngine.MakeMoveAsync(fromPos, toPos);
                if (result.Success)
                {
                    HandleMove(move, result);
                }
                else if (result.NeedsPromotion)
                {
                    // Prolog đã xác định đây là nước đi phong cấp, gọi UI phong cấp
                    HandlePromotion(move.FromPos, move.ToPos);
                }
            }
        }

        private void HandlePromotion(Position from, Position to)
        {
            pieceImages[to.Row, to.Column].Source = Images.GetImage(gameState.CurrentPlayer, PieceType.Pawn);
            pieceImages[from.Row, from.Column].Source = null;

            PromotionMenu promMenu = new PromotionMenu(gameState.CurrentPlayer);
            MenuContainer.Content = promMenu;

            promMenu.PieceSelected += async type =>
            {
                MenuContainer.Content = null;

                // Gửi lựa chọn phong cấp vào Prolog (async)
                string prologType;
                switch (type)
                {
                    case PieceType.Queen:
                        prologType = "queen";
                        break;
                    case PieceType.Rook:
                        prologType = "rook";
                        break;
                    case PieceType.Bishop:
                        prologType = "bishop";
                        break;
                    case PieceType.Knight:
                        prologType = "knight";
                        break;
                    default:
                        prologType = "queen";
                        break;
                }

                int fromPos = (7 - from.Row) * 8 + from.Column;
                int toPos = (7 - to.Row) * 8 + to.Column;

                var result = await PrologEngine.MakeMoveWithPromotionAsync(fromPos, toPos, prologType);
                if (result.Success)
                {
                    Move promMove = new PawnPromotion(from, to, type);
                    HandleMove(promMove, result);

                    WarningTextBlock.Text = result.Status == "CHECK" ? "Chiếu tướng!" : null;

                    if (result.Status == "CHECKMATE" || result.Status == "STALEMATE")
                    {
                        UnableClick();
                        moveList = new Stack<Tuple<Move, Piece>>(gameState.Moved.ToArray());
                        HideHighlights();
                        CellGrid.IsEnabled = false;
                        if (redTimer != null) StopTimer();
                        RaiseGameOverEvent(gameState);
                    }
                }
            };
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
                WhiteCapturedGrid.Children.Add(image);
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
                int count = WhiteCapturedGrid.Children.Count;
                if (count > 0)
                    WhiteCapturedGrid.Children.RemoveAt(count - 1);
            }
        }
        private void UndoAiCapturedGrid(Piece piece)
        {
            if (piece == null) return;
            int count = BlackCapturedGrid.Children.Count;
            if (count > 0)
                BlackCapturedGrid.Children.RemoveAt(count - 1);
        }
        public void ShowPrevMove(Move move)
        {
            Color color = Color.FromArgb(155, 207, 255, 112);
            posMoved[move.FromPos.Row, move.FromPos.Column].Fill = new SolidColorBrush(color);
            posMoved[move.ToPos.Row, move.ToPos.Column].Fill = new SolidColorBrush(color);
        }
        public void HidePrevMove(Move move)
        {
            posMoved[move.FromPos.Row, move.FromPos.Column].Fill = Brushes.Transparent;
            posMoved[move.ToPos.Row, move.ToPos.Column].Fill = Brushes.Transparent;
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

        public static readonly RoutedEvent PawnPromotionEvent = EventManager.RegisterRoutedEvent(
"PawnPromotion", RoutingStrategy.Bubble, typeof(RoutedEventHandler), typeof(GameUserControl));

        public event RoutedEventHandler PawnPromotion
        {
            add { AddHandler(PawnPromotionEvent, value); }
            remove { RemoveHandler(PawnPromotionEvent, value); }
        }

        protected void RaisePawnPromotionEvent()
        {
            RaiseEvent(new RoutedEventArgs(PawnPromotionEvent));
        }
        #endregion
    }
}
