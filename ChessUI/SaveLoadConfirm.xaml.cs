using System;
using System.Collections.Generic;
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
    /// Interaction logic for SaveLoadConfirm.xaml
    /// </summary>
    public partial class SaveLoadConfirm : UserControl
    {
        public event Action<bool> result;
        public SaveLoadConfirm()
        {
            InitializeComponent();
        }
        public void SetMessage(string message)
        {
            Message.Text = message;
        }
        private void YesButton_Click(object sender, RoutedEventArgs e)
        {
            result?.Invoke(true);
        }
        private void NoButton_Click(Object sender, RoutedEventArgs e)
        {
            result?.Invoke(false);
        }
    }
}
