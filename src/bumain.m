classdef main < matlab.apps.AppBase
    
    % Properties that correspond to app components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        TabGroup               matlab.ui.container.TabGroup
        MainTab                matlab.ui.container.Tab
    end
    
    properties (Access = private)
        ChecklistTabComponent  % ChecklistTab instance
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

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 1 1133 608];

            % Create MainTab
            app.MainTab = uitab(app.TabGroup);
            app.MainTab.Title = 'Main';

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

