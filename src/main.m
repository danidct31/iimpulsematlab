classdef main < matlab.apps.AppBase
    
    % Complete project:
        % Checklist
        % Tapes
        % Consumption
        % Tyres
        % FI - export, python and basemap
        % Engine brake
        % Rythm
        % File Share
        % Honda Sheets

        % Project timeline:
            % 1. Proper excel
            % 2. Matlab
            % 3. AI in Matlab

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        TabGroup               matlab.ui.container.TabGroup
        MainTab                matlab.ui.container.Tab
    end
    
    properties (Access = private)
        ChecklistTabComponent      % ChecklistTab instance
        EngineTemperatureTabComponent  % EngineTemperatureTab instance
        ConsumptionTabComponent   % ConsumptionTab instance
        TyresTabComponent         % Tyres tab instance
        FuelInjectionTabComponent % Fuel Injection tab instance
        EngineBrakeTabComponent   % Engine Brake tab instance
        RythmTabComponent         % Rythm tab instance
        FileShareTabComponent     % File Share tab instance
        HondaSheetsTabComponent   % Honda Sheets tab instance
    end
    
    methods (Access = private)
        
        % Code that executes after component creation
        function StartupFcn(app)
            % Maximize the window
            app.UIFigure.WindowState = 'maximized';
            
            % Initialize checklist tab
            % Store checklist data in data/processed directory
            appDir = fileparts(mfilename('fullpath'));
            projectRoot = fileparts(appDir); % Go up from src/ to project root
            dataDir = fullfile(projectRoot, 'data', 'processed');
            
            % Create directory if it doesn't exist
            if ~isfolder(dataDir)
                mkdir(dataDir);
            end
            
            csvPath = fullfile(dataDir, 'checklistData.csv');
            app.ChecklistTabComponent = ChecklistTab(app.TabGroup, app.UIFigure, csvPath, 40);
            
            % Initialize Engine Temperature tab
            engineTempPath = fullfile(dataDir, 'enginetemperature.csv');
            app.EngineTemperatureTabComponent = EngineTemperatureTab(app.TabGroup, app.UIFigure, engineTempPath);
            
            % Initialize Consumption tab
            consumptionPath = fullfile(dataDir, 'consumption.csv');
            app.ConsumptionTabComponent = ConsumptionTab(app.TabGroup, app.UIFigure, consumptionPath);
            
            % Initialize Rythm tab
            rawDataDir = fullfile(projectRoot, 'data', 'raw');
            ridersCsvPath = fullfile(rawDataDir, 'motogp_analysis_riders.csv');
            app.RythmTabComponent = RythmTab(app.TabGroup, app.UIFigure, ridersCsvPath);
            
            % Initialize empty placeholder tabs
            app.TyresTabComponent = EmptyTab(app.TabGroup, app.UIFigure, 'Tyres');
            app.FuelInjectionTabComponent = EmptyTab(app.TabGroup, app.UIFigure, 'Fuel Injection');
            app.EngineBrakeTabComponent = EmptyTab(app.TabGroup, app.UIFigure, 'Engine Brake');
            app.FileShareTabComponent = EmptyTab(app.TabGroup, app.UIFigure, 'File Share');
            app.HondaSheetsTabComponent = EmptyTab(app.TabGroup, app.UIFigure, 'Honda Sheets');
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1133 632];
            app.UIFigure.Name = 'IIMPULSE Racing App';
            app.UIFigure.Pointer = 'arrow';
            app.UIFigure.Color = [0.3 0.3 0.3]; % Dark grey background

            % Create TabGroup - positioned at the top
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 1 1133 632]; % Full height, starting from top
            % Try to set background color (may not be supported in all MATLAB versions)
            try
                app.TabGroup.BackgroundColor = [0.3 0.3 0.3]; % Dark grey
            catch
                % BackgroundColor may not be supported for TabGroup
            end

            % Create MainTab
            app.MainTab = uitab(app.TabGroup);
            app.MainTab.Title = 'Main';
            % Set tab background to dark grey
            try
                app.MainTab.BackgroundColor = [0.3 0.3 0.3]; % Dark grey
            catch
                % BackgroundColor may not be directly supported, will set via container
            end
            
            % Create a container for MainTab with dark grey background
            mainGrid = uigridlayout(app.MainTab, [1 1]);
            mainGrid.BackgroundColor = [0.3 0.3 0.3]; % Dark grey background

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = main
            
            % Add utils directory to path so ChecklistTab and ChecklistManager can be found
            % This must happen before creating components that use these classes
            utilsPath = fullfile(fileparts(mfilename('fullpath')), 'utils');
            if ~isfolder(utilsPath)
                error('Utils directory not found at: %s', utilsPath);
            end
            addpath(utilsPath);

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @StartupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end

