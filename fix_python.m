% FIX_PYTHON Quick script to configure Python and test it
% This will show you what Python MATLAB is using and help configure it

fprintf('=== Current Python Configuration ===\n');
try
    currentPython = pyversion;
    fprintf('Python version: %s\n', currentPython);
    fprintf('Executable: %s\n\n', pyversion('executable'));
catch
    fprintf('Python not configured yet\n\n');
end

fprintf('=== Testing pandas import ===\n');
try
    pandas = py.importlib.import_module('pandas');
    fprintf('✓ pandas is available! Version: %s\n', char(pandas.__version__));
    fprintf('\nPython is correctly configured. You can run main now.\n');
catch ME
    fprintf('✗ pandas is NOT available: %s\n\n', ME.message);
    
    fprintf('=== Attempting to configure Python ===\n');
    venvPython = 'C:\Users\MLav\PycharmProjects\motogp-telemetry-ai\.venv\Scripts\python.exe';
    
    if ~isfile(venvPython)
        venvPython = 'C:\Users\MLav\PycharmProjects\motogp-telemetry-ai\venv\Scripts\python.exe';
    end
    
    if isfile(venvPython)
        fprintf('Found virtual environment: %s\n', venvPython);
        fprintf('Configuring MATLAB to use this Python...\n');
        
        try
            pyversion(venvPython);
            fprintf('✓ Python configured!\n');
            fprintf('\n⚠️  IMPORTANT: You MUST restart MATLAB for this to take effect!\n');
            fprintf('After restarting, run: main\n');
        catch ME2
            fprintf('✗ Could not configure: %s\n', ME2.message);
            fprintf('\nYou may need to restart MATLAB first, then run this script again.\n');
        end
    else
        fprintf('✗ Virtual environment not found at: %s\n', venvPython);
        fprintf('\nPlease manually configure Python:\n');
        fprintf('1. Find your Python executable that has pandas installed\n');
        fprintf('2. Run: pyversion(''path/to/python.exe'')\n');
        fprintf('3. Restart MATLAB\n');
        fprintf('4. Run: main\n');
    end
end

