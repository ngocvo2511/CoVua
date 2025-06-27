using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;

namespace ChessUI.Menus
{
    /// <summary>
    /// Interaction logic for HistoryMenu.xaml
    /// </summary>
    public partial class HistoryMenu : UserControl
    {
        public HistoryMenu()
        {
            InitializeComponent();
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

        //public void LoadHistory()
        //{
        //    List<GameHistory> history = LocalGameHistoryService.LoadGameHistory();

        //    HistoryList.ItemsSource = history;
        //}
        private void HistoryList_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (HistoryList.SelectedItem is ChessLogic.GameRecord selectedRecord)
            {
                // Gọi replay hoặc load lại ván đấu
                LoadGameFromFile(selectedRecord.FilePath);

                // Bỏ chọn sau khi click để chọn lại được sau này
                HistoryList.SelectedItem = null;
            }
        }
        private void LoadGameFromFile(string filePath)
        {
            // Giả sử bạn có một phương thức để tải lại ván đấu từ file
            // Ví dụ: GameLoader.LoadGame(filePath);
            MessageBox.Show($"Loading game from {filePath}", "Load Game", MessageBoxButton.OK, MessageBoxImage.Information);
        }
    }
}
