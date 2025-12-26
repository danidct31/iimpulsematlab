% CHECK_PYTHON Check Python configuration in MATLAB
% Run this script to diagnose and fix Python/pandas issues

fprintf('=== Python Configuration Check ===\n\n');

% Check current Python version
try
    pyVersion = pyversion;
    fprintf('Current Python version: %s\n', pyVersion);
    fprintf('Python executable: %s\n', pyversion('executable'));
catch
    fprintf('Python is not configured in MATLAB.\n');
    fprintf('Attempting to configure...\n');
end

% Try to find Python with pandas
fprintf('\n=== Checking for Python with pandas ===\n');

% Common Python paths on Windows
pythonPaths = {
    'C:\Python*\python.exe',
    'C:\Program Files\Python*\python.exe',
    'C:\Users\MLav\AppData\Local\Programs\Python\Python*\python.exe',
    'C:\Users\MLav\anaconda3\python.exe',
    'C:\Users\MLav\miniconda3\python.exe',
    'C:\ProgramData\Anaconda3\python.exe',
    'C:\ProgramData\Miniconda3\python.exe'
};

% Also check if there's a virtual environment in the Python project
pycharmPath = 'C:\Users\MLav\PycharmProjects\motogp-telemetry-ai';
if isfolder(pycharmPath)
    venvPaths = {
        fullfile(pycharmPath, 'venv', 'Scripts', 'python.exe'),
        fullfile(pycharmPath, '.venv', 'Scripts', 'python.exe'),
        fullfile(pycharmPath, 'env', 'Scripts', 'python.exe')
    };
    pythonPaths = [venvPaths; pythonPaths];
end

foundPython = '';
for i = 1:length(pythonPaths)
    pathPattern = pythonPaths{i};
    if contains(pathPattern, '*')
        % Try to expand wildcard
        dirPath = fileparts(pathPattern);
        dirPath = strrep(dirPath, '*', '');
        if isfolder(dirPath)
            files = dir(pathPattern);
            if ~isempty(files)
                testPath = fullfile(files(1).folder, files(1).name);
            else
                continue;
            end
        else
            continue;
        end
    else
        testPath = pathPattern;
    end
    
    if isfile(testPath)
        fprintf('Found Python: %s\n', testPath);
        % Test if pandas is available
        try
            cmd = sprintf('"%s" -c "import pandas; print(pandas.__version__)"', testPath);
            [status, result] = system(cmd);
            if status == 0
                fprintf('  ✓ pandas is installed (version: %s)\n', strtrim(result));
                if isempty(foundPython)
                    foundPython = testPath;
                    fprintf('  → This Python will be configured\n');
                end
            else
                fprintf('  ✗ pandas is NOT installed\n');
            end
        catch
            fprintf('  ? Could not check for pandas\n');
        end
    end
end

if isempty(foundPython)
    fprintf('\n=== No Python with pandas found automatically ===\n');
    fprintf('Please manually configure Python:\n');
    fprintf('1. Find your Python executable (usually where pandas is installed)\n');
    fprintf('2. Run: pyversion("path/to/python.exe")\n');
    fprintf('3. Verify: py.importlib.import_module("pandas")\n');
else
    fprintf('\n=== Configuring MATLAB to use Python ===\n');
    try
        pyversion(foundPython);
        fprintf('Successfully configured Python: %s\n', foundPython);
        
        % Test import
        fprintf('\n=== Testing pandas import ===\n');
        pandas = py.importlib.import_module('pandas');
        fprintf('✓ pandas imported successfully!\n');
        fprintf('  Version: %s\n', char(pandas.__version__));
        
    catch ME
        fprintf('Error configuring Python: %s\n', ME.message);
        fprintf('You may need to restart MATLAB after configuring Python.\n');
    end
end

fprintf('\n=== Done ===\n');

