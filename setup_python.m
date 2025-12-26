% SETUP_PYTHON Configure MATLAB to use the correct Python environment
% Run this ONCE before running main.m

fprintf('=== Configuring Python for MATLAB ===\n\n');

% Path to Python virtual environment
venvPython = 'C:\Users\MLav\PycharmProjects\motogp-telemetry-ai\.venv\Scripts\python.exe';

% Check if venv exists
if ~isfile(venvPython)
    venvPython = 'C:\Users\MLav\PycharmProjects\motogp-telemetry-ai\venv\Scripts\python.exe';
end

if isfile(venvPython)
    fprintf('Found Python virtual environment: %s\n', venvPython);
    
    % Configure MATLAB to use this Python
    try
        pyversion(venvPython);
        fprintf('✓ Python configured successfully!\n\n');
        
        % Test pandas import
        fprintf('Testing pandas import...\n');
        pandas = py.importlib.import_module('pandas');
        fprintf('✓ pandas imported successfully! Version: %s\n\n', char(pandas.__version__));
        
        fprintf('=== Setup Complete ===\n');
        fprintf('You can now run: main\n');
        
    catch ME
        fprintf('✗ Error configuring Python: %s\n', ME.message);
        fprintf('\nYou may need to:\n');
        fprintf('1. Restart MATLAB after running this script\n');
        fprintf('2. Then run: main\n');
    end
else
    fprintf('✗ Virtual environment not found at: %s\n', venvPython);
    fprintf('\nPlease check the Python path or install pandas in your Python environment.\n');
end

