namespace ChessLogic
{
    public class Result
    {
        public EndReason Reason { get; }
        public Player Winner { get; }

        public Result(Player winner, EndReason reason)
        {
            Reason = reason;
            Winner = winner;
        }

        public static Result Win(Player winner, EndReason reason)
        {
            return new Result(winner, reason);
        }

        public static Result Draw(EndReason reason)
        {
            return new Result(Player.None, reason);
        }
    }
}
