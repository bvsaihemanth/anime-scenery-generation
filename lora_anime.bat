@echo off
REM ===================================================================
REM train_hands_lora_with_convert.bat
REM Uses local v1-5 safetensors -> converts to diffusers format if needed -> trains on 100_hands
REM ===================================================================

REM ---------- EDIT THESE PATHS if you want different files ----------
set "PYENV=C:\Users\bomma\Desktop\DEEP LEARNING\lora310_py310\Scripts\python.exe"
set "SD_SCRIPTS=C:\Users\bomma\Desktop\DEEP LEARNING\Anime_project\sd-scripts"

REM <-- Use this v1-5 pruned safetensors as base checkpoint (you found this) -->
set "SAFETENS_PATH=C:\Users\bomma\Desktop\DEEP LEARNING\Anime_project\stable-diffusion-webui\models\Stable-diffusion\v1-5-pruned-emaonly.safetensors"

REM Where to put converted diffusers model folder
set "DIFFUSERS_MODEL_DIR=C:\Users\bomma\Desktop\DEEP LEARNING\Anime_project\models\v1-5-diffusers"

REM Dataset (direct mode on 100_hands)
set "TRAIN_DATA_DIR=C:\Users\bomma\Desktop\DEEP LEARNING\Anime_project\anime_hands\dataset\100_hands"

REM Output / logs
set "OUTPUT_DIR=C:\Users\bomma\Desktop\DEEP LEARNING\Anime_project\loras\hands_lora"
set "LOGGING_DIR=C:\Users\bomma\Desktop\DEEP LEARNING\Anime_project\logs\hands_lora"

REM Hyperparams (edit as needed)
set "RESOLUTION=512,512"
set "NETWORK_MODULE=networks.lora"
set "TEXT_ENCODER_LR=5e-05"
set "UNET_LR=2e-04"
set "NETWORK_DIM=8"
set "NETWORK_ALPHA=16"
set "BATCH_SIZE=1"
set "MAX_STEPS=3000"
set "SAVE_EVERY=500"
set "MIXED_PRECISION=fp16"
set "OPTIMIZER=AdamW8bit"
set "CACHE_LATENTS=--cache_latents"
set "SEED=42"

REM Sampling disabled
set "SAMPLE_EVERY_N_STEPS=0"
set "SAMPLE_EVERY_N_EPOCHS=0"

REM Debug: set to --debug_dataset to print dataset detection details
set "DEBUG_DATASET="

echo ============================================================
echo 1) Check files and conversion
echo SAFETENS_PATH: %SAFETENS_PATH%
echo DIFFUSERS_MODEL_DIR: %DIFFUSERS_MODEL_DIR%
echo TRAIN_DATA_DIR: %TRAIN_DATA_DIR%
echo Output dir: %OUTPUT_DIR%
echo ============================================================

REM ---------- sanity checks ----------
if not exist "%SAFETENS_PATH%" (
  echo ERROR: cannot find the safetensors file at:
  echo   %SAFETENS_PATH%
  echo Please verify the path and try again.
  pause
  exit /b 1
)

REM ---------- convert if needed ----------
if not exist "%DIFFUSERS_MODEL_DIR%\model_index.json" (
  echo Diffusers-format model not found. Starting conversion from safetensors...
  echo This may take a minute or two.
  "%PYENV%" -m diffusers.pipelines.stable_diffusion.convert_from_ckpt ^
    --checkpoint_path "%SAFETENS_PATH%" ^
    --dump_path "%DIFFUSERS_MODEL_DIR%" ^
    --from_safetensors
  if errorlevel 1 (
    echo Conversion failed. Check the conversion output above for errors.
    pause
    exit /b 1
  )
) else (
  echo Found existing diffusers model at "%DIFFUSERS_MODEL_DIR%". Skipping conversion.
)

REM ---------- confirm dataset has images ----------
powershell -NoProfile -Command "(Get-ChildItem -Path '%TRAIN_DATA_DIR%' -Include .jpg,.jpeg,.png,.webp -File -Recurse | Measure-Object).Count"

REM ---------- run training (direct on 100_hands) ----------
echo Running training...
"%PYENV%" "%SD_SCRIPTS%\train_network.py" ^
 --pretrained_model_name_or_path "%DIFFUSERS_MODEL_DIR%" ^
 --train_data_dir "%TRAIN_DATA_DIR%" ^
 --resolution=%RESOLUTION% ^
 --output_dir "%OUTPUT_DIR%" ^
 --logging_dir "%LOGGING_DIR%" ^
 --network_module %NETWORK_MODULE% ^
 --text_encoder_lr %TEXT_ENCODER_LR% ^
 --unet_lr %UNET_LR% ^
 --network_dim %NETWORK_DIM% ^
 --network_alpha %NETWORK_ALPHA% ^
 --train_batch_size %BATCH_SIZE% ^
 --max_train_steps %MAX_STEPS% ^
 --save_every_n_steps %SAVE_EVERY% ^
 --mixed_precision %MIXED_PRECISION% ^
 --optimizer_type %OPTIMIZER% ^
 %CACHE_LATENTS% ^
 --seed %SEED% ^
 --sample_every_n_steps %SAMPLE_EVERY_N_STEPS% ^
 --sample_every_n_epochs %SAMPLE_EVERY_N_EPOCHS% ^
 %DEBUG_DATASET%

echo Training finished (or stopped). Press any key to close.
pause