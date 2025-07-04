using ChessLogic;
using ChessLogic.GameStates.GameState;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
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
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace ChessUI
{
    /// <summary>
    /// Interaction logic for SaveSlotControl.xaml
    /// </summary>
    public partial class SaveSlotControl : UserControl
    {
        public ObservableCollection<string> SaveSlots { get; set; } = new ObservableCollection<string>();
        //private readonly string[] SaveFiles = new string[5]
        //{
        //    "save1.chess",
        //    "save2.chess",
        //    "save3.chess",
        //    "save4.chess",
        //    "save5.chess"
        //};
        private readonly string SaveDirectory;
        private bool isSave;
        private GameState currentGameState;
        public SaveSlotControl(GameState gameState)
        {
            InitializeComponent();
            this.currentGameState = gameState;
            this.isSave = true;
            title.Text = "LƯU";
            string projectRoot = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\..\..\");
            SaveDirectory = System.IO.Path.Combine(projectRoot, "SaveData");
            if (!Directory.Exists(SaveDirectory))
            {
                Directory.CreateDirectory(SaveDirectory);
            }
            LoadFileToList();
            SaveSlotList.ItemsSource = SaveSlots;
        }
        public SaveSlotControl()
        {
            InitializeComponent();
            this.isSave = false;
            title.Text = "TẢI";
            string projectRoot = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\..\..\");
            SaveDirectory = System.IO.Path.Combine(projectRoot, "SaveData");
            if (!Directory.Exists(SaveDirectory))
            {
                Directory.CreateDirectory(SaveDirectory);
            }
            LoadFileToList();
            SaveSlotList.ItemsSource = SaveSlots;
        }
        private void LoadFileToList()
        {
            SaveSlots.Clear();

            for (int i = 0; i < 10; i++)
            {
                string filePath = System.IO.Path.Combine(SaveDirectory,"save"+ (i+1) +".chess");

                if (File.Exists(filePath))
                {
                    DateTime lastWriteTime = File.GetLastWriteTime(filePath);
                    SaveSlots.Add($"{lastWriteTime:ddd, dd/MM/yyyy HH:mm:ss}");
                }
                else
                {
                    SaveSlots.Add("Trống");
                }
            }
        }

        public static readonly RoutedEvent CloseButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "CloseButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(SaveSlotControl)
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
        public static readonly RoutedEvent SelectedLoadSlotEvent = EventManager.RegisterRoutedEvent(
            "SelectedLoadSlot",
            RoutingStrategy.Bubble,
            typeof(EventHandler<SaveSlotEventArgs>),
            typeof(SaveSlotControl)
        );
        public event EventHandler<SaveSlotEventArgs> SelectedLoadSlot
        {
            add { AddHandler(SelectedLoadSlotEvent, value); }
            remove { RemoveHandler(SelectedLoadSlotEvent, value); }
        }

        private async void SaveSlotList_MouseUp(object sender, MouseButtonEventArgs e)
        {
            int index = SaveSlotList.SelectedIndex;
            if (index < 0 || index >= 10) return;
            string filePath = System.IO.Path.Combine(SaveDirectory, "save" + (index+1) + ".chess");
            if (isSave == true)
            {
                int timeRed = currentGameState.timeRemainingRed;
                int timeBlack = currentGameState.timeRemainingBlack;
                if (File.Exists(filePath))
                {
                    ShowConfirmationDialog("Bạn có muốn ghi đè trận đấu trước đó?", async result =>
                    {
                        if (result)
                        {
                            SaveService.Save(currentGameState, filePath, timeRed, timeBlack);
                            LoadFileToList();
                        }
                    });
                }
                else
                {
                    SaveService.Save(currentGameState, filePath, timeRed, timeBlack);
                    LoadFileToList();
                }
            }
            else
            {
                if (File.Exists(filePath))
                {
                    ShowConfirmationDialog("Bạn có muốn tải trận đấu này?", result =>
                    {
                        if (result)
                        {
                            RaiseEvent(new SaveSlotEventArgs(SelectedLoadSlotEvent, filePath));
                        }
                    });
                }
            }
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
    public class SaveSlotEventArgs : RoutedEventArgs
    {
        public string FilePath { get; }

        public SaveSlotEventArgs(RoutedEvent routedEvent, string filePath) : base(routedEvent)
        {
            FilePath = filePath;
        }
    }
}
