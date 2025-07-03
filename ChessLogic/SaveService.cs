using ChessLogic.GameStates;
using ChessLogic.GameStates.GameState;
using ChessLogic.Pieces;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Threading.Tasks;

namespace ChessLogic
{
    public class SaveService
    {
        public static async Task Save(GameState gameState, string fileName, int timeRed, int timeBlack)
        {
            GameStateForSave gameStateForSave = await ToSave(gameState);
            gameStateForSave.depth = (int)((gameState is GameStateAI) ? await PrologEngine.GetDepthAsync() : 0);
            gameStateForSave.CurrentPlayer = (await PrologEngine.GetCurrentPlayerAsync() == Player.White) ? "White" : "Black";
            gameStateForSave.timeRemainingWhite = timeRed;
            gameStateForSave.timeRemainingBlack = timeBlack;
            gameStateForSave.historyBoard = await PrologEngine.GetRawHistoryAsync();
            gameStateForSave.CapturedWhitePiece = new List<string>();
            gameStateForSave.CapturedBlackPiece = new List<string>();
            foreach (var piece in gameState.CapturedWhitePiece) gameStateForSave.CapturedWhitePiece.Add(piece.ToString());
            foreach (var piece in gameState.CapturedBlackPiece) gameStateForSave.CapturedBlackPiece.Add(piece.ToString());
            File.WriteAllText(fileName, JsonSerializer.Serialize(gameStateForSave, new JsonSerializerOptions { WriteIndented = true }));
        }
        public static GameStateForLoad Load(string fileName)
        {
            string json = File.ReadAllText(fileName);
            GameStateForSave gameStateForSave = JsonSerializer.Deserialize<GameStateForSave>(json);
            GameStateForLoad gameStateForLoad = fromSave(gameStateForSave);
            return gameStateForLoad;
        }
        public static async Task<GameStateForSave> ToSave(GameState gameState)
        {
            GameStateForSave gameStateForSave = new GameStateForSave();
            gameStateForSave.GameType = gameState is GameState2P? "GameState2P" : "GameStateAI";
            gameStateForSave.depth = (int)((gameState is GameStateAI) ? await PrologEngine.GetDepthAsync() : 0);
            gameStateForSave.CurrentPlayer = (await PrologEngine.GetCurrentPlayerAsync() == Player.White) ? "White" : "Black";
            gameStateForSave.timeRemainingWhite = gameState.timeRemainingRed;
            gameStateForSave.timeRemainingBlack = gameState.timeRemainingBlack;
            gameStateForSave.historyBoard = await PrologEngine.GetRawHistoryAsync();
            gameStateForSave.CapturedWhitePiece = new List<string>();
            gameStateForSave.CapturedBlackPiece = new List<string>();
            foreach (var piece in gameState.CapturedWhitePiece) gameStateForSave.CapturedWhitePiece.Add(piece.ToString());
            foreach (var piece in gameState.CapturedBlackPiece) gameStateForSave.CapturedBlackPiece.Add(piece.ToString());
            return gameStateForSave;
        }  
        public static GameStateForLoad fromSave(GameStateForSave gameStateForSave)
        {
            GameStateForLoad gameStateForLoad = new GameStateForLoad();
            gameStateForLoad.GameType = gameStateForSave.GameType;
            gameStateForLoad.depth = gameStateForSave.depth;
            gameStateForLoad.CurrentPlayer = (gameStateForSave.CurrentPlayer == "White") ? Player.White : Player.Black;
            gameStateForLoad.timeRemainingWhite = gameStateForSave.timeRemainingWhite;
            gameStateForLoad.timeRemainingBlack = gameStateForSave.timeRemainingBlack;
            gameStateForLoad.historyBoard = gameStateForSave.historyBoard;
            var mapping = new Dictionary<string, Func<Player, Piece>>
            {
                {"bK",color=>new King(color)},
                {"wK",color=>new King(color)},
                {"bP",color=>new Pawn(color)},
                {"wP",color=>new Pawn(color)},
                {"bR",color=>new Rook(color)},
                {"wR",color=>new Rook(color)},
                {"bB",color=>new Bishop(color)},
                {"wB",color=>new Bishop(color)},
                {"bQ",color=>new Queen(color)},
                {"wQ",color=>new Queen(color)},
                {"bKn",color=>new Knight(color)},
                {"wKn",color=>new Knight(color)}
            };
            List<Piece> blackPiece = new List<Piece>();
            foreach (var piece in gameStateForSave.CapturedBlackPiece)
            {
                if (mapping.TryGetValue(piece, out var CreatePiece))
                {
                    blackPiece.Add(CreatePiece(Player.Black));
                }
            }
            List<Piece> whitePiece = new List<Piece>();
            foreach (var piece in gameStateForSave.CapturedWhitePiece)
            {
                if (mapping.TryGetValue(piece, out var CreatePiece))
                {
                    whitePiece.Add(CreatePiece(Player.White));
                }
            }
            gameStateForLoad.CapturedBlackPiece = blackPiece;
            gameStateForLoad.CapturedWhitePiece = whitePiece;
            return gameStateForLoad;
        }
    }
    public class SaveHistory { 
    
    }
}

