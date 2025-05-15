using System.Windows;
using System.Windows.Controls;

namespace ChessUI.Menus
{
    /// <summary>
    /// Interaction logic for ConfirmMenu.xaml
    /// </summary>
    public partial class ConfirmMenu : UserControl
    {
        public ConfirmMenu()
        {
            InitializeComponent();
        }

        public static readonly RoutedEvent YesButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "YesButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(ConfirmMenu)
        );
        public event RoutedEventHandler YesButtonClicked
        {
            add { AddHandler(YesButtonClickedEvent, value); }
            remove { RemoveHandler(YesButtonClickedEvent, value); }
        }
        private void YesButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(YesButtonClickedEvent));
        }

        public static readonly RoutedEvent NoButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "NoButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(ConfirmMenu)
            );
        public event RoutedEventHandler NoButtonClicked
        {
            add { AddHandler(NoButtonClickedEvent, value); }
            remove { RemoveHandler(NoButtonClickedEvent, value); }
        }
        private void NoButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(NoButtonClickedEvent));
        }
    }
}
