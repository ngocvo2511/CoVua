using ChessLogic.GameStates;
using ChessLogic.GameStates.GameState;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;

namespace ChessLogic
{
    public class SaveService
    {
        //public static void Save(GameState gameState, string fileName)
        //{
        //    GameStateForSave gameStateForSave = ToSave(gameState);
        //    File.WriteAllText(fileName, JsonSerializer.Serialize(gameStateForSave, new JsonSerializerOptions { WriteIndented = true }));
        //}
        //public static GameStateForLoad Load(string fileName)
        //{
        //    string json = File.ReadAllText(fileName);
        //    GameStateForSave gameStateForSave = JsonSerializer.Deserialize<GameStateForSave>(json);
        //    GameStateForLoad gameState = fromSave(gameStateForSave);
        //    return gameState;
        //}
        //public static GameStateForSave ToSave(GameState gameState)
        //{
        //    GameStateForSave gameStateForSave = new GameStateForSave();
            //gameStateForSave.GameType = gameState is GameState2P ? "GameState2P" : "GameStateAI";
            //gameStateForSave.noCapture = gameState.noCapture.ToList();
            //gameStateForSave.depth = (gameState is GameStateAI AI) ? AI.depth : null;
            //gameStateForSave.CurrentPlayer = (gameState.CurrentPlayer == Player.Black) ? "Black" : "Red";
            //gameStateForSave.timeRemainingRed = gameState.timeRemainingRed;
            //gameStateForSave.timeRemainingBlack = gameState.timeRemainingBlack;
            //gameStateForSave.stateHistory = gameState.getStateHistory();
            //gameStateForSave.Board = new List<string>();
            //gameStateForSave.Moved = new List<string>();
            //gameStateForSave.CapturedRedPiece = new List<string>();
            //gameStateForSave.CapturedBlackPiece = new List<string>();
            //gameStateForSave.stateString = gameState.stateString.ToList();
            //List<Tuple<Move, Piece>> currentMoved = gameState.Moved.ToList();
            //currentMoved.Reverse();
            //for (int i = 0; i < 10; i++)
            //{
            //    for (int j = 0; j < 9; j++)
            //    {
            //        if (gameState.Board[i, j] == null) gameStateForSave.Board.Add("n");
            //        else gameStateForSave.Board.Add(gameState.Board[i, j].ToString());
            //    }
            //}
            //foreach (var moved in currentMoved)
            //{
            //    gameStateForSave.Moved.Add(moved.Item1.FromPos.Row.ToString());
            //    gameStateForSave.Moved.Add(moved.Item1.FromPos.Column.ToString());
            //    gameStateForSave.Moved.Add(moved.Item1.ToPos.Row.ToString());
            //    gameStateForSave.Moved.Add(moved.Item1.ToPos.Column.ToString());
            //    if (moved.Item2 == null) gameStateForSave.Moved.Add("n");
            //    else gameStateForSave.Moved.Add(moved.Item2.ToString());
            //}
            //foreach (var piece in gameState.CapturedRedPiece) gameStateForSave.CapturedRedPiece.Add(piece.ToString());
            //foreach (var piece in gameState.CapturedBlackPiece) gameStateForSave.CapturedBlackPiece.Add(piece.ToString());
            //return gameStateForSave;
        //}
        //public static GameStateForLoad fromSave(GameStateForSave gameStateForSave)
        //{
            //GameStateForLoad gameStateForLoad = new GameStateForLoad();
            //var mapping = new Dictionary<string, Func<Player, Piece>>
            //{
            //    {"bA",color=>new Advisor(color)},
            //    {"rA",color=>new Advisor(color)},
            //    {"bH",color=>new Horse(color)},
            //    {"rH",color=>new Horse(color)},
            //    {"bCh",color=>new Chariot(color)},
            //    {"rCh",color=>new Chariot(color)},
            //    {"bC",color=>new Cannon(color)},
            //    {"rC",color=>new Cannon(color)},
            //    {"bE",color=>new Elephant(color)},
            //    {"rE",color=>new Elephant(color)},
            //    {"bS",color=>new Soldier(color)},
            //    {"rS",color=>new Soldier(color)},
            //    {"bG",color=>new General(color)},
            //    {"rG",color=>new General(color)}
            //};
            //Board board = new Board();
            //int k = 0;
            //for (int i = 0; i < 10; i++)
            //{
            //    for (int j = 0; j < 9; j++)
            //    {
            //        if (gameStateForSave.Board[k] == "n") board[i, j] = null;
            //        else if (mapping.TryGetValue(gameStateForSave.Board[k], out var CreatePiece))
            //        {
            //            Player color = (gameStateForSave.Board[k].StartsWith('b')) ? Player.Black : Player.Red;
            //            board[i, j] = CreatePiece(color);
            //        }
            //        ++k;
            //    }
            //}
            //Stack<Tuple<Move, Piece>> Moved = new Stack<Tuple<Move, Piece>>();
            //int x = 0;
            //while (x < gameStateForSave.Moved.Count)
            //{
            //    Position fromPos = new Position(int.Parse(gameStateForSave.Moved[x]), int.Parse(gameStateForSave.Moved[x + 1]));
            //    Position toPos = new Position(int.Parse(gameStateForSave.Moved[x + 2]), int.Parse(gameStateForSave.Moved[x + 3]));
            //    Move move = new NormalMove(fromPos, toPos);
            //    Piece capturedPiece = null;
            //    if (gameStateForSave.Moved[x + 4] == "n") capturedPiece = null;
            //    else if (mapping.TryGetValue(gameStateForSave.Moved[x + 4], out var CreatePiece))
            //    {
            //        Player color = (gameStateForSave.Moved[x + 4].StartsWith('b')) ? Player.Black : Player.Red;
            //        capturedPiece = CreatePiece(color);
            //    }
            //    Moved.Push(Tuple.Create(move, capturedPiece));
            //    x += 5;
            //}
            //for (int i = 0; i < gameStateForSave.stateHistory.Count - 1; i += 2)
            //{
            //    gameStateForLoad.stateHistory[gameStateForSave.stateHistory[i]] = int.Parse(gameStateForSave.stateHistory[i + 1]);
            //}
            //List<Piece> blackPiece = new List<Piece>();
            //foreach (var piece in gameStateForSave.CapturedBlackPiece)
            //{
            //    if (mapping.TryGetValue(piece, out var CreatePiece))
            //    {
            //        blackPiece.Add(CreatePiece(Player.Black));
            //    }
            //}
            //List<Piece> redPiece = new List<Piece>();
            //foreach (var piece in gameStateForSave.CapturedRedPiece)
            //{
            //    if (mapping.TryGetValue(piece, out var CreatePiece))
            //    {
            //        redPiece.Add(CreatePiece(Player.Red));
            //    }
            //}
            //gameStateForLoad.Board = board;
            //gameStateForLoad.Moved = Moved;
            //gameStateForLoad.CapturedRedPiece = redPiece;
            //gameStateForLoad.CapturedBlackPiece = blackPiece;
            //gameStateForLoad.CurrentPlayer = (gameStateForSave.CurrentPlayer == "Black") ? Player.Black : Player.Red;
            //List<int> loadNoCapture = gameStateForSave.noCapture;
            //loadNoCapture.Reverse();
            //gameStateForLoad.noCapture = new Stack<int>(loadNoCapture);
            //List<string> strings = gameStateForSave.stateString;
            //strings.Reverse();
            //gameStateForLoad.stateString = new Stack<string>(strings);
            //gameStateForLoad.depth = gameStateForSave.depth ?? 0;
            //gameStateForLoad.GameType = gameStateForSave.GameType;
            //gameStateForLoad.timeRemainingBlack = gameStateForSave.timeRemainingBlack;
            //gameStateForLoad.timeRemainingRed = gameStateForSave.timeRemainingRed;
            //return gameStateForLoad;
        //}
    }
}

