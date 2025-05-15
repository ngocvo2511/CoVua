using System.Windows;
using System.Windows.Controls;

namespace ChessUI.Menus
{
    /// <summary>
    /// Interaction logic for NotificationMenu.xaml
    /// </summary>
    public partial class NotificationMenu : UserControl
    {
        public NotificationMenu()
        {
            InitializeComponent();
        }

        private void OkButton_Click(object sender, RoutedEventArgs e)
        {
            this.Visibility = Visibility.Collapsed;
        }
    }
}
