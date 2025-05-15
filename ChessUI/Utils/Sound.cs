using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Media;

namespace ChessUI
{
    public class Sound
    {
        private static MediaPlayer buttonClickSound = new MediaPlayer();
        private static MediaPlayer gameOverSound = new MediaPlayer();
        private static MediaPlayer moveSound = new MediaPlayer();
        private static double volume = 50;

        public static void SetVolume(double volume)
        {
            Sound.volume = volume / 100;
        }
        public static double GetVolume()
        {
            return volume;
        }

        public static void PlayButtonClickSound()
        {
            buttonClickSound.Open(new Uri("Assets/Sounds/buttonClickSound.mp3", UriKind.Relative));
            buttonClickSound.Volume = volume;
            buttonClickSound.Play();
        }
        public static void PlayGameOverSound()
        {
            gameOverSound.Open(new Uri("Assets/Sounds/gameOverSound.mp3", UriKind.Relative));
            gameOverSound.Volume = volume;
            gameOverSound.Play();
        }
        public static void PlayMoveSound()
        {
            moveSound.Open(new Uri("Assets/Sounds/moveSound.mp3", UriKind.Relative));
            moveSound.Volume = volume;
            moveSound.Play();
        }
    }
}
