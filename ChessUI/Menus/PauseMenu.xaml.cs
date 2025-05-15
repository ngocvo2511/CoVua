using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace ChessUI.Menus
{
    /// <summary>
    /// Interaction logic for PauseMenu.xaml
    /// </summary>
    public partial class PauseMenu : UserControl
    {
        public PauseMenu()
        {
            InitializeComponent();
        }

        public static readonly RoutedEvent ContinueButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "ContinueButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(PauseMenu)
        );

        public event RoutedEventHandler ContinueButtonClicked
        {
            add { AddHandler(ContinueButtonClickedEvent, value); }
            remove { RemoveHandler(ContinueButtonClickedEvent, value); }
        }

        private void ContinueButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(ContinueButtonClickedEvent));
        }

        public static readonly RoutedEvent NewButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "NewButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(PauseMenu)
        );

        public event RoutedEventHandler NewButtonClicked
        {
            add { AddHandler(NewButtonClickedEvent, value); }
            remove { RemoveHandler(NewButtonClickedEvent, value); }
        }

        private void NewButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(NewButtonClickedEvent));
        }

        public static readonly RoutedEvent HomeButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "HomeButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(PauseMenu)
        );

        public event RoutedEventHandler HomeButtonClicked
        {
            add { AddHandler(HomeButtonClickedEvent, value); }
            remove { RemoveHandler(HomeButtonClickedEvent, value); }
        }

        private void HomeButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(HomeButtonClickedEvent));
        }

        public static readonly RoutedEvent SettingsButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "SettingsButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(PauseMenu)
        );

        public event RoutedEventHandler SettingsButtonClicked
        {
            add { AddHandler(SettingsButtonClickedEvent, value); }
            remove { RemoveHandler(SettingsButtonClickedEvent, value); }
        }

        private void SettingsButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(SettingsButtonClickedEvent));
        }

        public static readonly RoutedEvent CloseAppButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "CloseAppButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(PauseMenu)
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
