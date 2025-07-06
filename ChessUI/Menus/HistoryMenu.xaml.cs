using ChessLogic;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Windows;
using System.Windows.Controls;

namespace ChessUI.Menus
{
    /// <summary>
    /// Interaction logic for HistoryMenu.xaml
    /// </summary>
    public partial class HistoryMenu : UserControl
    {
        public ObservableCollection<HistoryDisplay> Histories { get; } = new ObservableCollection<HistoryDisplay>();
        public HistoryMenu()
        {
            InitializeComponent();
            DataContext = this;
            LoadHistory();
        }
        public static readonly RoutedEvent CloseButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "CloseButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(HistoryMenu)
        );
        public event RoutedEventHandler CloseButtonClicked
        {
            add { AddHandler(CloseButtonClickedEvent, value); }
            remove { RemoveHandler(CloseButtonClickedEvent, value); }
        }

        private void CloseButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(CloseButtonClickedEvent));
        }

        public static readonly RoutedEvent HistorySelectedEvent =
        EventManager.RegisterRoutedEvent(
            "HistorySelected",
            RoutingStrategy.Bubble,
            typeof(EventHandler<HistorySelectedEventArgs>),
            typeof(HistoryMenu));

        public event EventHandler<HistorySelectedEventArgs> HistorySelected
        {
            add => AddHandler(HistorySelectedEvent, value);
            remove => RemoveHandler(HistorySelectedEvent, value);
        }
        private void LoadHistory()
        {
            Histories.Clear();

            string projectRoot = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\..\..");
            string saveDirectory = Path.Combine(projectRoot, "SaveHistory");
            if (!Directory.Exists(saveDirectory)) return;

            var files = Directory.EnumerateFiles(saveDirectory, "*.History") 
                         .OrderByDescending(File.GetCreationTime);
            foreach (var file in files)
            {
                try
                {
                    var json = File.ReadAllText(file);
                    var record = JsonSerializer.Deserialize<HistoryRecord>(json);

                    if (record != null)
                        Histories.Add(ToDisplay(record, file));
                }
                catch (Exception ex)
                {
                    Debug.WriteLine($"Không đọc được {file}: {ex.Message}");
                }
            }
        }
        private static HistoryDisplay ToDisplay(HistoryRecord r, string filePath)
        {
            string gameMode = r.GameMode == "2P" ? "Chế độ: Chơi 2 người" : "Chế độ: Chơi với AI";
            string winner = r.Winner == "White" ? "TRẮNG THẮNG" : (r.Winner == "Black"?"ĐEN THẮNG" : "HOÀ");           
            string playTime = File.GetCreationTime(filePath).ToString("dd-MM-yyyy HH:mm");

            string img = r.Winner == "White" ? "/Assets/Images/KingW.png"
           : r.Winner == "Black" ? "/Assets/Images/KingB.png"
           : "/Assets/Images/icon.ico";

            string reason = "Lí do: ";
            switch (r.Reason)
            {
                case "Checkmate":
                    reason += "Đối thủ bị chiếu bí";
                    break;
                case "Stalemate":
                    reason += "Đối thủ hết nước đi";
                    break;
                case "InsufficientMaterial":
                    reason += "Hòa vì thiếu quân";
                    break;
                case "FiftyMoveRule":
                    reason += "Hòa vì 50 nước không ăn quân";
                    break;
                case "ThreefoldRepetition":
                    reason += "Hoà vì lặp lại nước đi 3 lần";
                    break;
                case "TimeForfeit":
                    reason += "Đối thủ hết thời gian";
                    break;
                default:
                    reason += "Lý do không xác định";
                    break;
            }

            return new HistoryDisplay
            {
                GameMode = gameMode,
                Reason = reason,
                Winner = winner,
                PlayTime = playTime,
                ImagePath = img,
                FilePath = filePath
            };
        }
        private void HistoryList_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if(!(HistoryList.SelectedItem is HistoryDisplay selectedHistory))
            {
                return;
            }
            ShowConfirmationDialog("Bạn có muốn tải trận đấu này?", result =>
            {
                if (result)
                {
                    RaiseEvent(new HistorySelectedEventArgs(HistorySelectedEvent, selectedHistory));
                }
            });
        }
        private void ShowConfirmationDialog(string message, Action<bool> callback)
        {
            ConfirmationControl.SetMessage(message);
            ConfirmationControl.result += (result) =>
            {
                ConfirmationDialogContainer.Visibility = Visibility.Collapsed;
                callback(result);
            };
            ConfirmationDialogContainer.Visibility = Visibility.Visible;
        }

    }
    public class HistoryDisplay
    {
        public string GameMode { get; set; }
        public string Reason { get; set; }
        public string Winner { get; set; }
        public string PlayTime { get; set; }
        public string ImagePath { get; set; }
        internal string FilePath { get; set; }
    }

    public class HistorySelectedEventArgs : RoutedEventArgs
    {
        public HistoryDisplay Record { get; }
        public HistorySelectedEventArgs(RoutedEvent routedEvent, HistoryDisplay record)
            : base(routedEvent) => Record = record;
    }
}
