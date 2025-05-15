using System.Windows;
using System.Windows.Controls;

namespace ChessUI.Menus
{
    /// <summary>
    /// Interaction logic for SearchingMatchMenu.xaml
    /// </summary>
    public partial class SearchingMatchMenu : UserControl
    {
        public SearchingMatchMenu()
        {
            InitializeComponent();
        }
        public static readonly RoutedEvent BackButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "BackButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(SearchingMatchMenu)
            );
        public event RoutedEventHandler BackButtonClicked
        {
            add { AddHandler(BackButtonClickedEvent, value); }
            remove { RemoveHandler(BackButtonClickedEvent, value); }
        }

        private void BackButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(BackButtonClickedEvent));
        }
    }
}
