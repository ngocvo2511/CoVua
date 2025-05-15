using System;
using System.Windows;
using System.Windows.Controls;

namespace ChessUI.Menus
{
    /// <summary>
    /// Interaction logic for SettingsMenu.xaml
    /// </summary>
    public partial class SettingsMenu : UserControl
    {
        public SettingsModel settings = new SettingsModel();
        public event Action<SettingsModel> SettingsChanged;
        private bool isInitializing = true;


        public SettingsMenu(SettingsModel settings)
        {
            InitializeComponent();
            isInitializing = true;

            this.settings = settings;
            VolumeSlider.Value = settings.Volume;
            VolumeValue.Text = settings.Volume.ToString();

            humanFirst.IsChecked = settings.HumanFirst;
            botFirst.IsChecked = !settings.HumanFirst;

            isTimeLimit.IsChecked = settings.IsTimeLimit;
            TimeLimitTextBox.Text = settings.TimeLimit.ToString();


            isInitializing = false;
            TimeLimitTextBox.IsEnabled = settings.IsTimeLimit;
        }

        public static readonly RoutedEvent CloseButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "CloseButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(SettingsMenu)
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

        private void humanFirst_Checked(object sender, RoutedEventArgs e)
        {
            if (isInitializing) return;
            Sound.PlayButtonClickSound();

            settings.HumanFirst = true;
            SettingsChanged?.Invoke(settings);
        }

        private void botFirst_Checked(object sender, RoutedEventArgs e)
        {
            if (isInitializing) return;
            Sound.PlayButtonClickSound();

            settings.HumanFirst = false;
            SettingsChanged?.Invoke(settings);
        }

        private void VolumeSlider_ValueChanged(object sender, RoutedEventArgs e)
        {
            if (isInitializing) return;
            if (double.TryParse(VolumeValue.Text, out double volume))
            {
                settings.Volume = (int)VolumeSlider.Value;
                VolumeValue.Text = settings.Volume.ToString();
                SettingsChanged?.Invoke(settings);
            }
        }

        private void isTimeLimit_Checked(object sender, RoutedEventArgs e)
        {
            if (isInitializing) return;
            Sound.PlayButtonClickSound();

            settings.IsTimeLimit = true;
            TimeLimitTextBox.IsEnabled = true;
            SettingsChanged?.Invoke(settings);
        }

        private void isTimeLimit_Unchecked(object sender, RoutedEventArgs e)
        {
            if (isInitializing) return;
            Sound.PlayButtonClickSound();

            settings.IsTimeLimit = false;
            TimeLimitTextBox.IsEnabled = false;
            SettingsChanged?.Invoke(settings);
        }
        private void TimeLimitTextBox_LostFocus(object sender, RoutedEventArgs e)
        {
            int time;
            if (!int.TryParse(TimeLimitTextBox.Text, out time))
            {
                TimeLimitTextBox.Text = settings.TimeLimit.ToString();
            }
            else
            {
                TimeLimitTextBox.Text = time.ToString();
                settings.TimeLimit = time;
                SettingsChanged?.Invoke(settings);
            }
        }
    }
}
