using ChessLogic.GameStates.GameState;
using ChessLogic;
using ChessUI.Menus;
using System;
using System.Collections.Generic;
using System.ComponentModel;
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
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        GameUserControl gameUserControl;
        private SettingsModel settingsModel = new SettingsModel();

        GameOverMenu gameOverMenu;

        bool onGame = false;
        Player color = Player.White;
        int time = 600;
        public MainWindow()
        {
            InitializeComponent();

            CreateMainMenu();
            this.Closing += MainWindow_Closing;
        }

        #region MainMenu
        private void CreateMainMenu()
        {
            onGame = false;

            MainMenu mainMenu = new MainMenu();

            mainMenu.PlayButtonClicked += MainMenu_PlayButtonClicked;
            mainMenu.InstructionsButtonClicked += MainMenu_InstructionsButtonClicked;
            mainMenu.SettingsButtonClicked += SettingsButtonClicked;
            mainMenu.HistoryButtonClicked += MainMenu_HistoryButtonClicked;
            //mainMenu.LoadButtonClicked += MainMenu_LoadButton_Clicked;
            mainMenu.CloseAppButtonClicked += CloseAppButtonClicked;

            mainWindowGrid.Children.Clear();
            mainWindowGrid.Children.Add(mainMenu);
        }

        private void MainMenu_HistoryButtonClicked(object sender, RoutedEventArgs e)
        {
            try
            {
                string rootPath = System.IO.Path.GetFullPath(System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\..\.."));
                string prologPath = System.IO.Path.Combine(rootPath, "ChessLogic", "Prolog", "test.pl");
                PrologEngine.Initialize(prologPath);

                var results = PrologEngine.QuerySingleVariable("greeting(X)", "X");
                MessageBox.Show(string.Join(Environment.NewLine, results));
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi: " + ex.Message);
            }
        }

        private void MainMenu_PlayButtonClicked(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            CreateSelectGameModeMenu();
        }

        private void MainMenu_InstructionsButtonClicked(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            CreateInstructionMenu();
        }
        //private void MainMenu_HistoryButtonClicked(object sender, RoutedEventArgs e)
        //{
        //    Sound.PlayButtonClickSound();
        //    CreateHistoryMenu();
        //}

        //private void MainMenu_LoadButton_Clicked(object sender, RoutedEventArgs e)
        //{
        //    Sound.PlayButtonClickSound();
        //    CreateLoadMenu();
        //}
        #endregion

        #region SelectGameModeMenu
        private void CreateSelectGameModeMenu()
        {
            SelectGameModeMenu selectGameModeMenu = new SelectGameModeMenu();

            selectGameModeMenu.CloseButtonClicked += CloseButtonClicked;
            selectGameModeMenu.PlayWithBotButtonClicked += SelectGameMode_PlayWithBotButtonClicked;
            selectGameModeMenu.TwoPlayerButtonClicked += SelectGameMode_TwoPlayerButtonClicked;

            mainWindowGrid.Children.Add(selectGameModeMenu);
        }

        private void SelectGameMode_PlayWithBotButtonClicked(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            CreateSelectDifficultMenu();
        }

        private void SelectGameMode_TwoPlayerButtonClicked(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            CreateViewGame2P();
        }


        #endregion

        #region SelectDifficultMenu
        private void CreateSelectDifficultMenu()
        {
            GameDifficultyMenu gameDifficultyMenu = new GameDifficultyMenu();

            gameDifficultyMenu.BackButtonClicked += GameDifficultyMenu_BackButtonClicked;
            gameDifficultyMenu.PlayEasyBotButtonClicked += GameDifficultyMenu_PlayEasyBotButtonClicked;
            gameDifficultyMenu.PlayNormalBotButtonClicked += GameDifficultyMenu_PlayNormalBotButtonClicked;
            gameDifficultyMenu.PlayHardBotButtonClicked += GameDifficultyMenu_PlayHardBotButtonClicked;

            mainWindowGrid.Children.Add(gameDifficultyMenu);
        }
        private void GameDifficultyMenu_BackButtonClicked(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            mainWindowGrid.Children.RemoveAt(mainWindowGrid.Children.Count - 1);
        }
        private void GameDifficultyMenu_PlayEasyBotButtonClicked(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            CreateViewGameAI(2);
        }
        private void GameDifficultyMenu_PlayNormalBotButtonClicked(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            CreateViewGameAI(3);
        }
        private void GameDifficultyMenu_PlayHardBotButtonClicked(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            CreateViewGameAI(4);
        }
        #endregion

        #region InstructionMenu
        private void CreateInstructionMenu()
        {
            InstructionsMenu instructionsMenu = new InstructionsMenu();

            instructionsMenu.CloseButtonClicked += CloseButtonClicked;

            mainWindowGrid.Children.Add(instructionsMenu);
        }
        #endregion

        #region SettingsMenu
        private void CreateSettingsMenu()
        {
            SettingsMenu settingsMenu = new SettingsMenu(settingsModel);
            mainWindowGrid.Children.Add(settingsMenu);

            settingsMenu.humanFirst.IsEnabled = !onGame;
            settingsMenu.botFirst.IsEnabled = !onGame;
            settingsMenu.isTimeLimit.IsEnabled = !onGame;
            settingsMenu.TimeLimitTextBox.IsEnabled = !onGame && settingsModel.IsTimeLimit;

            settingsMenu.CloseButtonClicked += CloseButtonClicked;
            settingsMenu.SettingsChanged += SettingsMenu_SettingsChanged;
        }

        private void SettingsMenu_SettingsChanged(SettingsModel updatedSettings)
        {
            Sound.SetVolume((int)updatedSettings.Volume);
            settingsModel = updatedSettings;
        }
        #endregion

        #region HistoryMenu
        //private void CreateHistoryMenu()
        //{
        //    HistoryMenu historyMenu = new HistoryMenu();

        //    historyMenu.CloseButtonClicked += CloseButtonClicked;

        //    historyMenu.LoadHistory();
        //    mainWindowGrid.Children.Add(historyMenu);
        //}
        #endregion

        #region PauseMenu
        private void CreatePauseMenu()
        {
            if (time != 0) gameUserControl.StopTimer();

            PauseMenu pauseMenu = new PauseMenu();

            pauseMenu.ContinueButtonClicked += ContinueButtonClicked;
            pauseMenu.NewButtonClicked += NewButtonClicked;
            pauseMenu.HomeButtonClicked += PauseMenu_HomeButtonClicked;
            pauseMenu.SettingsButtonClicked += SettingsButtonClicked;

            mainWindowGrid.Children.Add(pauseMenu);
        }

        private void PauseMenu_HomeButtonClicked(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            CreateConfirmMenu();
        }
        #endregion

        #region ConfirmMenu

        private void CreateConfirmMenu(bool wantToCloseApp = false)
        {
            ConfirmMenu confirmMenu = new ConfirmMenu();

            if (wantToCloseApp) confirmMenu.YesButtonClicked += CloseApp;
            else confirmMenu.YesButtonClicked += ConfirmMenu_YesButtonClicked;
            confirmMenu.NoButtonClicked += CloseButtonClicked;

            mainWindowGrid.Children.Add(confirmMenu);
        }

        private void ConfirmMenu_YesButtonClicked(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            CreateMainMenu();
        }
        #endregion

        #region ViewGameAI
        private void CreateViewGameAI(int difficulty)
        {
            onGame = true;
            if (gameUserControl != null) gameUserControl.ResetTimer();
            color = settingsModel.HumanFirst ? Player.White : Player.Black;
            gameUserControl = new GameUserControl(color, settingsModel.IsTimeLimit ? settingsModel.TimeLimit * 60 : 0, true, difficulty);
            gameUserControl.PauseButtonClicked += PauseButtonClicked;
            //gameUserControl.SaveButtonClicked += SaveButtonClicked;
            gameUserControl.GameOver += OnGameOver;
            gameUserControl.CloseAppButtonClicked += CloseAppButtonClicked;

            mainWindowGrid.Children.Clear();
            mainWindowGrid.Children.Add(gameUserControl);
        }
        #endregion

        #region ViewGame2P
        private void CreateViewGame2P()
        {
            onGame = true;
            if (gameUserControl != null) gameUserControl.ResetTimer();
            color = settingsModel.HumanFirst ? Player.White : Player.Black;
            gameUserControl = new GameUserControl(color, settingsModel.IsTimeLimit ? settingsModel.TimeLimit * 60 : 0, false);
            gameUserControl.PauseButtonClicked += PauseButtonClicked;
            //gameUserControl.SaveButtonClicked += SaveButtonClicked;
            gameUserControl.GameOver += OnGameOver;
            gameUserControl.CloseAppButtonClicked += CloseAppButtonClicked;

            mainWindowGrid.Children.Clear();
            mainWindowGrid.Children.Add(gameUserControl);
        }
        #endregion

        //#region ViewGameLoad
        //private void CreateViewGameLoad(GameStateForLoad gameStateForLoad)
        //{
        //    onGame = true;
        //    if (gameUserControl != null) gameUserControl.ResetTimer();
        //    gameUserControl = new GameUserControl(gameStateForLoad);
        //    gameUserControl.PauseButtonClicked += PauseButtonClicked;
        //    gameUserControl.SaveButtonClicked += SaveButtonClicked;
        //    gameUserControl.GameOver += OnGameOver;
        //    gameUserControl.CloseAppButtonClicked += CloseAppButtonClicked;

        //    mainWindowGrid.Children.Clear();
        //    mainWindowGrid.Children.Add(gameUserControl);
        //}
        //#endregion

        #region SaveMenu
        //private void CreateSaveMenu()
        //{
        //    saveloadSlotControl = new SaveSlotControl(gameUserControl.gameState);
        //    saveloadSlotControl.CloseButtonClicked += ContinueButtonClicked;

        //    mainWindowGrid.Children.Add(saveloadSlotControl);
        //}
        #endregion

        #region LoadMenu
        //private void CreateLoadMenu()
        //{
        //    saveloadSlotControl = new SaveSlotControl();
        //    saveloadSlotControl.CloseButtonClicked += CloseButtonClicked;
        //    saveloadSlotControl.SelectedLoadSlot += SelectedLoadSlot_Clicked;

        //    mainWindowGrid.Children.Add(saveloadSlotControl);
        //}

        //private void SelectedLoadSlot_Clicked(object sender, SaveSlotEventArgs e)
        //{
        //    Sound.PlayButtonClickSound();
        //    GameStateForLoad gameStateForLoad = SaveService.Load(e.FilePath);
        //    CreateViewGameLoad(gameStateForLoad);
        //}
        #endregion







        #region ShareFunction
        private void CloseButtonClicked(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            CloseAMenu();
        }

        private void SettingsButtonClicked(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            CreateSettingsMenu();
        }


        //private void SaveButtonClicked(object sender, RoutedEventArgs e)
        //{
        //    if (time != 0) gameUserControl.StopTimer();
        //    Sound.PlayButtonClickSound();
        //    CreateSaveMenu();
        //}
        private void PauseButtonClicked(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            CreatePauseMenu();
        }

        private void ContinueButtonClicked(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            if (time != 0) gameUserControl.ContinueTimer();
            CloseAMenu();
        }

        private void NewButtonClicked(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            CreateSelectGameModeMenu();
        }

        private void CloseAMenu()
        {
            mainWindowGrid.Children.RemoveAt(mainWindowGrid.Children.Count - 1);
        }
        #endregion

        #region ViewGameOver
        private void OnGameOver(object sender, RoutedEventArgs e)
        {
            if (e is RoutedPropertyChangedEventArgs<GameState> gameOverEventArgs)
            {
                GameState gameState = gameOverEventArgs.NewValue;

                Sound.PlayGameOverSound();
                gameOverMenu = new GameOverMenu(gameState);

                gameOverMenu.NewButtonClicked += NewButtonClicked;
                gameOverMenu.HomeButtonClicked += GameOverMenu_HomeButtonClicked;
                gameOverMenu.ReviewButtonClicked += GameOverMenu_ReviewButtonClicked;

                mainWindowGrid.Children.Add(gameOverMenu);

                //LocalGameHistoryService.SaveGameHistory(gameOverMenu, gameState);
            }
        }

        private void GameOverMenu_HomeButtonClicked(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            CreateMainMenu();
        }
        private void GameOverMenu_ReviewButtonClicked(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            CloseAMenu();
            gameUserControl.Review();
        }
        #endregion

        private async void MainWindow_Closing(object sender, CancelEventArgs e)
        {

        }

        private void CloseAppButtonClicked(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            CreateConfirmMenu(true);
        }

        private void CloseApp(object sender, RoutedEventArgs e)
        {
            Application.Current.Shutdown();
        }
    }
}
