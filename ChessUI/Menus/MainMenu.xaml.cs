using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace ChessUI.Menus
{
    /// <summary>
    /// Interaction logic for MainMenu.xaml
    /// </summary>
    public partial class MainMenu : UserControl
    {
        public MainMenu()
        {
            InitializeComponent();
        }

        public event RoutedEventHandler PlayButtonClicked
        {
            add { AddHandler(PlayButtonClickedEvent, value); }
            remove { RemoveHandler(PlayButtonClickedEvent, value); }
        }

        public static readonly RoutedEvent PlayButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "PlayButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(MainMenu)
        );

        private void PlayButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(PlayButtonClickedEvent));
        }

        public event RoutedEventHandler InstructionsButtonClicked
        {
            add { AddHandler(InstructionsButtonClickedEvent, value); }
            remove { RemoveHandler(InstructionsButtonClickedEvent, value); }
        }

        public static readonly RoutedEvent InstructionsButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "InstructionsButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(MainMenu)
        );

        private void InstructionsButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(InstructionsButtonClickedEvent));
        }


        public event RoutedEventHandler SettingsButtonClicked
        {
            add { AddHandler(SettingsButtonClickedEvent, value); }
            remove { RemoveHandler(SettingsButtonClickedEvent, value); }
        }

        public static readonly RoutedEvent SettingsButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "SettingsButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(MainMenu)
        );
        private void SettingsButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(SettingsButtonClickedEvent));
        }
        public static readonly RoutedEvent HistoryButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "HistoryButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(MainMenu)
            );
        public event RoutedEventHandler HistoryButtonClicked
        {
            add { AddHandler(HistoryButtonClickedEvent, value); }
            remove { RemoveHandler(HistoryButtonClickedEvent, value); }
        }

        private void HistoryButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(HistoryButtonClickedEvent));
        }

        public event RoutedEventHandler LoadButtonClicked
        {
            add { AddHandler(LoadButtonClickedEvent, value); }
            remove { RemoveHandler(LoadButtonClickedEvent, value); }
        }
        public static readonly RoutedEvent LoadButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "LoadButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(MainMenu)

        );
        private void LoadButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(LoadButtonClickedEvent));
        }

        public static readonly RoutedEvent CloseAppButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "CloseAppButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(MainMenu)
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
            else
                Application.Current.MainWindow.WindowState = WindowState.Maximized;
        }

        private void TitleBar_MouseDown(object sender, MouseButtonEventArgs e)
        {
            if (e.LeftButton == MouseButtonState.Pressed)
            {
                Application.Current.MainWindow.DragMove();
            }
        }
    }
}
