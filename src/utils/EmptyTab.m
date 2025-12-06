classdef EmptyTab < handle
    % EmptyTab
    % A simple empty tab that can be used as a placeholder
    
    properties
        ParentTabGroup
        ParentFigure
        Tab
        TabTitle
    end
    
    methods
        function obj = EmptyTab(tabGroup, parentFigure, tabTitle)
            obj.ParentTabGroup = tabGroup;
            obj.ParentFigure   = parentFigure;
            obj.TabTitle        = tabTitle;
            
            obj.createUI();
        end
    end
    
    methods (Access = private)
        
        function createUI(obj)
            % Create tab
            obj.Tab = uitab(obj.ParentTabGroup);
            obj.Tab.Title = obj.TabTitle;
            
            % Try to set tab background to dark grey
            try
                obj.Tab.BackgroundColor = [0.3 0.3 0.3]; % Dark grey
            catch
                % BackgroundColor may not be directly supported
            end
            
            % Create a simple label in the center
            mainGrid = uigridlayout(obj.Tab, [1 1]);
            mainGrid.Padding = [20 20 20 20];
            mainGrid.BackgroundColor = [0.3 0.3 0.3]; % Dark grey background
            
            label = uilabel(mainGrid, ...
                'Text', sprintf('%s Tab', obj.TabTitle), ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 16, ...
                'FontColor', [1 1 1]); % White text for visibility
            label.Layout.Row = 1;
            label.Layout.Column = 1;
        end
    end
end

