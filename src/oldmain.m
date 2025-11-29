        classdef mainii < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        FileMenu               matlab.ui.container.Menu
        Menu_2                 matlab.ui.container.Menu
        OptionsMenu            matlab.ui.container.Menu
        IIMPULSERACINGDANIELDELCERROTURNERLabel  matlab.ui.control.Label
        TabGroup               matlab.ui.container.TabGroup
        MainTab                matlab.ui.container.Tab
        ChecklistTab           matlab.ui.container.Tab
        GeneralLabel           matlab.ui.control.Label
        PerRiderLabel          matlab.ui.control.Label
        PreRaceLabel           matlab.ui.control.Label
        UITableChecklist1      matlab.ui.control.Table
        UITableChecklist2      matlab.ui.control.Table
        UITableChecklist3      matlab.ui.control.Table
        SaveButton             matlab.ui.control.Button
        LoadButton             matlab.ui.control.Button
        EngineBrakeTab         matlab.ui.container.Tab
        EBMapTable             matlab.ui.control.Table
        EBGearDropDown         matlab.ui.control.DropDown
        DropDownLabel          matlab.ui.control.Label
        EBSaveXLSXButton       matlab.ui.control.Button
        EBTextArea             matlab.ui.control.TextArea
        AnswerLabel            matlab.ui.control.Label
        EBAskAssistantButton   matlab.ui.control.Button
        EBRequestEditField     matlab.ui.control.EditField
        RequestEditFieldLabel  matlab.ui.control.Label
        EBLoadCSVButton        matlab.ui.control.Button
        EBUIAxes               matlab.ui.control.UIAxes
        EBUIAxesAI             matlab.ui.control.UIAxes
        SpecsheetTab           matlab.ui.container.Tab
        FITab                  matlab.ui.container.Tab
        UITable3               matlab.ui.control.Table
        UITable2               matlab.ui.control.Table
        UITable                matlab.ui.control.Table
        FISaveButton           matlab.ui.control.Button
        FILoadButton           matlab.ui.control.Button
        ReportTab              matlab.ui.container.Tab
        FiAiTab                matlab.ui.container.Tab
        EBstatTab              matlab.ui.container.Tab
        EBstatLoadButton       matlab.ui.control.Button
        EBstatAxes4            matlab.ui.control.UIAxes
        EBstatAxes3            matlab.ui.control.UIAxes
        EBstatAxes2            matlab.ui.control.UIAxes
        EBstatAxes1            matlab.ui.control.UIAxes

        % --- NEW: Report Analysis tab + controls ---
        ReportAnalysisTab      matlab.ui.container.Tab
        RA_RidersButton        matlab.ui.control.Button
        RA_LapsButton          matlab.ui.control.Button
        RA_SectorsButton       matlab.ui.control.Button
        RA_RidersTable         matlab.ui.control.Table
    end

    
   
    
    
    properties (Access = private)
        %Engine Brake
        EBFile string = ""      % path to the loaded CSV
        EBData table  = table() % table read from the CSV
        EBFileId string = ""        % OpenAI file_id after upload
        EBUploadedPath string = ""  % path the current file_id corresponds to
        EBFeature    % instance of helper class below

        % Checklists
        ChecklistCSVPath string = fullfile(pwd,'checklistData.csv')
        ItemsPerList double = 40

        % --- FI (Fuel Injection) ---
        FIXVals double = [0.5 2 5 8 11 15 20 25 30 35 40 50 60 70 80 97];
        FIYVals double = [1000 1500 2000 2500 2750 3000 3500 4000 4500 5000 5500 6000 ...
                          6500 7000 7500 8000 8500 9000 9500 10000 10500 11000 11500 ...
                          12000 12250 12500 12750 13000 13250 13500 14000 14010];
        
        FITbl1 matlab.ui.control.Table
        FITbl2 matlab.ui.control.Table
        FITbl3 matlab.ui.control.Table
        FISaveBtn matlab.ui.control.Button
        FILoadBtn matlab.ui.control.Button
        
        FICSV1 string = fullfile(pwd,'FI_Table1.csv')  % pasteable source 1
        FICSV2 string = fullfile(pwd,'FI_Table2.csv')  % pasteable source 2

        FIPasteStart1 double = [1 1];   % current cursor (row,col) in UITable
        FIPasteStart2 double = [1 1];   % current cursor in UITable2



        FIPlot3DButton matlab.ui.control.Button
        SpecTbl          matlab.ui.control.Table
        SpecProtMask     logical = false(0,0)
        SpecColNames     cell    = {}
        

        % ---- Report (Excel-backed) ----
        ReportFile string = fullfile(pwd,'Report.xlsx')
        
        % UI handles
        RptGrid                    matlab.ui.container.GridLayout
        RptA_Axes                  matlab.ui.control.UIAxes
        RptA_Table                 matlab.ui.control.Table
        RptB_Axes                  matlab.ui.control.UIAxes
        RptB_Table                 matlab.ui.control.Table
        RptBottom_Table            matlab.ui.control.Table
        
        RptLoadBtn                 matlab.ui.control.Button
        RptSaveBtn                 matlab.ui.control.Button
        
        % Optional: column presets (you can change these to match your Excel)
        RptA_Cols cell = {'X','Series 1','Series 2'}
        RptB_Cols cell = {'X','Series 1','Series 2'}
        RptBottom_Cols cell = {'Item','Value','Comments'}
        

        % --- FiAi tab / file picker + runner ---
        FiAiRunButton          matlab.ui.control.Button
        FiAiPickFiButton       matlab.ui.control.Button
        FiAiPickCsvButton      matlab.ui.control.Button
        FiAiStatusLabel        matlab.ui.control.Label
        FiAiInitialTable       matlab.ui.control.Table   % shows original fi.xlsx snapshot
        FiAiNewTable           matlab.ui.control.Table   % shows Python's corrected map
        FiAiNoteLabel          matlab.ui.control.Label

        

        % Selected paths (set by user)
        FiXlsxPath   string = ""     % user-chosen fi.xlsx path
        DataCsvPath  string = ""     % user-chosen telemetry CSV path

        % Snapshot of original fi.xlsx (kept in memory and backed up)
        FiInitialSnapshot table = table()

        % Project / Python locations (adjust to machine)
        ProjectRoot   string = "C:\Users\MLav\PycharmProjects\motogp-telemetry-ai";
        PyExePath     string = "C:\Users\MLav\PycharmProjects\motogp-telemetry-ai\.venv\Scripts\python.exe";
        PyScriptPath  string = "C:\Users\MLav\PycharmProjects\motogp-telemetry-ai\unified_system.py";

        % Folders used by Python
        RawDir        string = "C:\Users\MLav\PycharmProjects\motogp-telemetry-ai\data\raw";
        ProcessedDir  string = "C:\Users\MLav\PycharmProjects\motogp-telemetry-ai\data\processed"
    end
    
    methods (Access = private)

        function buildReportUI(app)
        % Layout: 3 rows
        app.RptGrid = uigridlayout(app.ReportTab,[3 1]);
        app.RptGrid.RowHeight   = {270, 270, '1x'};
        app.RptGrid.ColumnWidth = {'1x'};
    
        % ====== Top block (Graph A + Table A) ======
        top = uigridlayout(app.RptGrid,[1 2]);
        top.ColumnWidth = {'2x','1.2x'};
        top.Layout.Row = 1; top.Layout.Column = 1;
    
        app.RptA_Axes = uiaxes(top);
        title(app.RptA_Axes,'Report A'); xlabel(app.RptA_Axes,'X'); ylabel(app.RptA_Axes,'Y');
    
        app.RptA_Table = uitable(top,'ColumnEditable',true);
        app.RptA_Table.ColumnName = app.RptA_Cols;
        app.RptA_Table.Data = app.emptyReportTable(app.RptA_Cols, 20);
        app.RptA_Table.CellEditCallback = createCallbackFcn(app,@(~,~)app.plotFromTable(app.RptA_Table, app.RptA_Axes,'A'),true);
    
        % ====== Middle block (Graph B + Table B) ======
        mid = uigridlayout(app.RptGrid,[1 2]);
        mid.ColumnWidth = {'2x','1.2x'};
        mid.Layout.Row = 2; mid.Layout.Column = 1;
    
        app.RptB_Axes = uiaxes(mid);
        title(app.RptB_Axes,'Report B'); xlabel(app.RptB_Axes,'X'); ylabel(app.RptB_Axes,'Y');
    
        app.RptB_Table = uitable(mid,'ColumnEditable',true);
        app.RptB_Table.ColumnName = app.RptB_Cols;
        app.RptB_Table.Data = app.emptyReportTable(app.RptB_Cols, 20);
        app.RptB_Table.CellEditCallback = createCallbackFcn(app,@(~,~)app.plotFromTable(app.RptB_Table, app.RptB_Axes,'B'),true);
    
        % ====== Bottom block (Summary table) ======
        bot = uigridlayout(app.RptGrid,[1 1]);
        bot.Layout.Row = 3; bot.Layout.Column = 1;
    
        app.RptBottom_Table = uitable(bot,'ColumnEditable',true);
        app.RptBottom_Table.ColumnName = app.RptBottom_Cols;
        app.RptBottom_Table.Data = app.emptyReportTable(app.RptBottom_Cols, 15);
    
        % ====== Save / Load buttons (float in Report tab) ======
        app.RptLoadBtn = uibutton(app.ReportTab,'Text','Load Report',...
            'Position',[20 560 100 24],...
            'ButtonPushedFcn',@(~,~)app.loadReportXLSX());
        app.RptSaveBtn = uibutton(app.ReportTab,'Text','Save Report',...
            'Position',[130 560 100 24],...
            'ButtonPushedFcn',@(~,~)app.saveReportXLSX());
    end
    
    function T = emptyReportTable(app, headers, nRows)
        % Build a table with given headers (first numeric X, rest numeric except bottom)
        vars = cell(1,numel(headers));
        for i = 1:numel(headers)
            if i==1 && any(strcmpi(headers{i},{'X','Time','Lap','RPM'}))
                vars{i} = nan(nRows,1);
            elseif any(strcmpi(headers{i},{'Item','Comments','Note','Label'}))
                vars{i} = strings(nRows,1);
            else
                vars{i} = nan(nRows,1);
            end
        end
        T = table(vars{:},'VariableNames',matlab.lang.makeValidName(headers));
    end
    
    function plotFromTable(app, tbl, ax, tag)
        % Generic: first column is X, remaining numeric columns are plotted as series.
        T = tbl.Data;
        if isempty(T) || width(T)<2, cla(ax); return; end
    
        X = app.safeNumeric(T{:,1});
        seriesCount = width(T)-1;
        cla(ax); hold(ax,'on');
        for k = 1:seriesCount
            Y = app.safeNumeric(T{:,1+k});
            if all(isnan(X)) && all(isnan(Y)), continue; end
            plot(ax, X, Y, 'LineWidth',1.5); %#ok<*CPROP>
        end
        grid(ax,'on');
        legend(ax, string(tbl.ColumnName(2:end)), 'Location','best');
        hold(ax,'off');
    
        % Optional: title tweak
        if tag=="A", title(ax,'Report A'); else, title(ax,'Report B'); end
    end
    
    function v = safeNumeric(~, col)
        % Convert strings to doubles when needed; keep NaN where conversion fails
        if iscell(col), col = string(col); end
        if isstring(col)
            v = nan(size(col));
            for i=1:numel(col)
                tok = strrep(col(i),',','.'); % decimal comma friendly
                x = str2double(tok);
                if ~isnan(x), v(i)=x; end
            end
        elseif islogical(col)
            v = double(col);
        else
            v = double(col);
        end
    end
    
    function saveReportXLSX(app)
        % Saves all three tables into one XLSX (overwriting the sheets)
        try
            % A
            writetable(app.RptA_Table.Data, app.ReportFile, 'Sheet','GraphA','WriteMode','overwritesheet');
            % B
            writetable(app.RptB_Table.Data, app.ReportFile, 'Sheet','GraphB','WriteMode','overwritesheet');
            % Bottom
            writetable(app.RptBottom_Table.Data, app.ReportFile, 'Sheet','Summary','WriteMode','overwritesheet');
    
            % (Optional) save graph snapshots next to the file
            [p,n,~] = fileparts(app.ReportFile);
            exportgraphics(app.RptA_Axes, fullfile(p, n+"_GraphA.png"));
            exportgraphics(app.RptB_Axes, fullfile(p, n+"_GraphB.png"));
    
            uialert(app.UIFigure, "Report saved to "+app.ReportFile, 'Report');
        catch ME
            uialert(app.UIFigure, "Save failed: "+ME.message, 'Report','Icon','error');
        end
    end
    
    function loadReportXLSX(app)
        % Loads tables (if sheets exist) and refreshes plots
        try
            if isfile(app.ReportFile)
                % Try GraphA
                try
                    TA = readtable(app.ReportFile,'Sheet','GraphA','TextType','string');
                    TA = app.reconcileColumns(TA, app.RptA_Cols);
                    app.RptA_Table.Data = TA;
                catch, end
    
                % Try GraphB
                try
                    TB = readtable(app.ReportFile,'Sheet','GraphB','TextType','string');
                    TB = app.reconcileColumns(TB, app.RptB_Cols);
                    app.RptB_Table.Data = TB;
                catch, end
    
                % Try Summary
                try
                    TS = readtable(app.ReportFile,'Sheet','Summary','TextType','string');
                    TS = app.reconcileColumns(TS, app.RptBottom_Cols);
                    app.RptBottom_Table.Data = TS;
                catch, end
            end
    
            % Update plots
            app.plotFromTable(app.RptA_Table, app.RptA_Axes,'A');
            app.plotFromTable(app.RptB_Table, app.RptB_Axes,'B');
    
            uialert(app.UIFigure, "Report loaded from "+app.ReportFile, 'Report');
        catch ME
            uialert(app.UIFigure, "Load failed: "+ME.message, 'Report','Icon','error');
        end
    end
    
    function T = reconcileColumns(app, T, wantHeaders)
        % Keep only requested headers, add missing as empty, enforce order.
        wantVars = matlab.lang.makeValidName(wantHeaders);
        haveVars = string(T.Properties.VariableNames);
        % Add missing columns as NaN / "" depending on header type
        for i = 1:numel(wantVars)
            if ~ismember(wantVars{i}, haveVars)
                if i==1 && any(strcmpi(wantHeaders{i},{'X','Time','Lap','RPM'}))
                    T.(wantVars{i}) = nan(height(T),1);
                elseif any(strcmpi(wantHeaders{i},{'Item','Comments','Note','Label'}))
                    T.(wantVars{i}) = strings(height(T),1);
                else
                    T.(wantVars{i}) = nan(height(T),1);
                end
            end
        end
        % Reorder and drop extras
        T = T(:, wantVars);
        % Ensure fixed number of rows (optional)
        targetRows = max(height(T), 15);
        T = [T; app.emptyReportTable(wantHeaders, targetRows - height(T))];
    end


        %---- Checklist helpers ----------------------------------------------
        function initChecklistTable(~, tbl, n)
            tbl.Data = table(false(n,1), "Item " + string(1:n)', ...
                'VariableNames', {'Checked','Text'});
        end

        function refreshChecklistRowColors(~, tbl)
            D = tbl.Data;
            nRows = size(D,1);
            C = ones(nRows,3);
            if ~isempty(D) && any(D.Checked)
                C(D.Checked,:) = repmat([0.7 0.9 1], sum(D.Checked), 1);
            end
            tbl.BackgroundColor = C;
        end

        function saveAllChecklistsToSingleCSV(app)
            % Normalize each table and stack them: list1 (1–20), list2 (21–40), list3 (41–60)
            T1 = app.UITableChecklist1.Data; T1.Checked = logical(T1.Checked); T1.Text = string(T1.Text);
            T2 = app.UITableChecklist2.Data; T2.Checked = logical(T2.Checked); T2.Text = string(T2.Text);
            T3 = app.UITableChecklist3.Data; T3.Checked = logical(T3.Checked); T3.Text = string(T3.Text);
        
            % Force exactly ItemsPerList rows per list (pad/truncate)
            n = app.ItemsPerList;
            T1 = normalizeLen(T1,n); T2 = normalizeLen(T2,n); T3 = normalizeLen(T3,n);
        
            % Concatenate and write only the two columns
            T = [T1(:,{'Checked','Text'}); T2(:,{'Checked','Text'}); T3(:,{'Checked','Text'})];
            writetable(T, app.ChecklistCSVPath);
        
            function TT = normalizeLen(TT, nPer)
                % pad with defaults or truncate to exactly nPer
                if height(TT) < nPer
                    addN = nPer - height(TT);
                    TT = [TT; table(false(addN,1), "Item "+string(height(TT)+(1:addN))', ...
                         'VariableNames', {'Checked','Text'})];
                elseif height(TT) > nPer
                    TT = TT(1:nPer, :);
                end
            end
        end

        
        function loadAllChecklistsFromSingleCSV(app)
            file = app.ChecklistCSVPath;
            if ~isfile(file); return; end
        
            T = readtable(file, 'TextType','string');
            % Accept headers "Checked,Text" or "Check,Text"
            vars = string(T.Properties.VariableNames);
            if ismember("Check", vars) && ~ismember("Checked", vars)
                T.Properties.VariableNames{vars=="Check"} = "Checked";
                vars = string(T.Properties.VariableNames);
            end
            if ~all(ismember(["Checked","Text"], vars))
                uialert(app.UIFigure, "CSV must have columns: Checked, Text", 'Load'); return;
            end
        
            % Normalize types
            T.Checked = logical(T.Checked);
            T.Text    = string(T.Text);
        
            nPer = app.ItemsPerList;                 % usually 20
            % Ensure at least 3*nPer rows by padding with defaults; ignore extras
            need = 3*nPer;
            if height(T) < need
                addN = need - height(T);
                T = [T; table(false(addN,1), "Item "+string(height(T)+(1:addN))', ...
                    'VariableNames', {'Checked','Text'})];
            end
        
            % Chunk into the three UI tables
            idx1 = 1:nPer; 
            idx2 = nPer+1:2*nPer;
            idx3 = 2*nPer+1:3*nPer;
        
            app.UITableChecklist1.Data = T(idx1, {'Checked','Text'});
            app.UITableChecklist2.Data = T(idx2, {'Checked','Text'});
            app.UITableChecklist3.Data = T(idx3, {'Checked','Text'});
        
            app.refreshChecklistRowColors(app.UITableChecklist1);
            app.refreshChecklistRowColors(app.UITableChecklist2);
            app.refreshChecklistRowColors(app.UITableChecklist3);
        end

        function initFITable(app, tbl)
            % Create numeric matrix sized [numY x numX] initialized to NaN
            nR = numel(app.FIYVals);
            nC = numel(app.FIXVals);
            M  = nan(nR, nC);
        
            % Build a MATLAB table with variable names = X labels (as valid names)
            varNames = matlab.lang.makeValidName("x_" + string(app.FIXVals));
            T = array2table(M, 'VariableNames', varNames);
        
            % Show nice headers (display) while preserving valid var names
            tbl.Data = T;
            tbl.ColumnName = cellstr(string(app.FIXVals));    % show X on top
            tbl.RowName    = cellstr(string(app.FIYVals));    % show Y on left
            tbl.ColumnEditable = true(1, nC);
        end
        
        function updateFITable3(app)
            % Compute: ((T1 - T2) ./ T1) * 100
            if isempty(app.FITbl1) || isempty(app.FITbl2) || isempty(app.FITbl3)
                return;
            end
            T1 = app.FITbl1.Data;
            T2 = app.FITbl2.Data;
        
            % Ensure same shape/vars
            if ~isequal(T1.Properties.VariableNames, T2.Properties.VariableNames) ...
               || height(T1) ~= height(T2)
                return;
            end
        
            A = table2array(T1);
            B = table2array(T2);
        
            % Avoid warnings for 0/NaN
            C = (A - B) ./ A * 100;
            % Keep as NaN where A is 0 or NaN
            C(A == 0) = NaN;
        
            T3 = array2table(C, 'VariableNames', T1.Properties.VariableNames);
            app.FITbl3.Data = T3;
        end
        
        function FITableEdited(app, ~)
            % Called when user edits Table1 or Table2 -> recompute Table3
            app.updateFITable3();
        end
        
        function saveFICSV(app)
            % Save only source tables (1 and 2). Table 3 is derived on load.
            writetable(app.FITbl1.Data, app.FICSV1);
            writetable(app.FITbl2.Data, app.FICSV2);
        end
        
        function loadFICSV(app)
            % Re-init (ensures headers/shape), then load if files exist, then recompute.
            app.initFITable(app.FITbl1);
            app.initFITable(app.FITbl2);
            app.initFITable(app.FITbl3);
        
            if isfile(app.FICSV1)
                T1 = readtable(app.FICSV1, 'TextType','string');
                % Reconcile variable names with current spec (in case of edits)
                wantVars = app.FITbl1.Data.Properties.VariableNames;
                if isequal(wantVars, T1.Properties.VariableNames)
                    app.FITbl1.Data = T1;
                end
            end
        
            if isfile(app.FICSV2)
                T2 = readtable(app.FICSV2, 'TextType','string');
                wantVars = app.FITbl2.Data.Properties.VariableNames;
                if isequal(wantVars, T2.Properties.VariableNames)
                    app.FITbl2.Data = T2;
                end
            end
        
            app.updateFITable3();
        end

        function FI_SelectTbl1(app, event)
            if ~isempty(event.Indices)
                 app.FIPasteStart1 = event.Indices(1,:); % [row col]
            end
        end
        
        function FI_SelectTbl2(app, event)
            if ~isempty(event.Indices)
                app.FIPasteStart2 = event.Indices(1,:);
            end
        end

        function pasteClipboardIntoTbl(app, targetTbl, startRC)
            % Paste a multi-cell block copied from Excel into a uitable.
            % Assumes Excel clipboard format: columns = TAB, rows = newline.
            %
            % targetTbl : handle to app.UITable or app.UITable2
            % startRC   : [row col] to start pasting (use [1 1] for A1)
        
            % 1) Grab clipboard text
            raw = app.getClipboardTextSafe();
            if strlength(raw)==0
                uialert(app.UIFigure,'Clipboard is empty or unreadable. Copy from Excel and try again.','Paste');
                return;
            end
        
            % 2) Ensure table has the right size/headers
            app.ensureFITableReady(targetTbl);
        
            % 3) Normalize and parse (TAB between columns, NEWLINE between rows)
            raw   = replace(raw, char(160), ' ');       % NBSP -> space
            raw   = regexprep(raw, '\r\n|\r', '\n');    % unify newlines
            lines = strsplit(raw, '\n');
            lines = lines(~cellfun(@isempty, lines));
        
            % Split each line by tab
            cells = cellfun(@(L) strsplit(L, sprintf('\t')), lines, 'uni', 0);
        
            % Build numeric matrix M (non-numeric -> NaN)
            nr = numel(cells);
            nc = max(cellfun(@numel, cells));
            M  = nan(nr, nc);
            for i = 1:nr
                rowi = cells{i};
                for j = 1:numel(rowi)
                    tok = strtrim(rowi{j});
                    if tok == "" || tok == "-" || tok == "—"
                        M(i,j) = NaN; continue;
                    end
                    % Locale-friendly: decimal comma -> dot
                    tok = strrep(tok, ',', '.');
                    % Strip trailing percent (if any)
                    tok = regexprep(tok, '%$', '');
                    % Convert
                    v = str2double(tok);
                    if ~isnan(v), M(i,j) = v; end
                end
            end
        
            % 4) Write into the table starting at startRC (default A1)
            if nargin < 3 || isempty(startRC) || numel(startRC) ~= 2
                startRC = [1 1];
            end
            r0 = max(1, startRC(1));
            c0 = max(1, startRC(2));
        
            T = targetTbl.Data;              % MATLAB table
            A = table2array(T);              % numeric matrix
            [R,C] = size(A);
        
            % Fit to bounds
            r1 = min(R, r0 + nr - 1);
            c1 = min(C, c0 + nc - 1);
            if r1 < r0 || c1 < c0
                uialert(app.UIFigure,'Paste area is outside the table bounds.','Paste');
                return;
            end
        
            % Apply slice
            A(r0:r1, c0:c1) = M(1:(r1-r0+1), 1:(c1-c0+1));
        
            % 5) Write back and refresh computed table if needed
            targetTbl.Data = array2table(A, 'VariableNames', T.Properties.VariableNames);
        
            if targetTbl == app.UITable || targetTbl == app.UITable2
                app.updateFITable3();
            end
        end

        function txt = getClipboardTextSafe(app)
            % Try MATLAB clipboard
            txt = "";
            try
                c = clipboard('paste');
                if ~isempty(c), txt = string(c); return; end
            catch
            end
            % Java fallback (works on most MATLAB installs)
            try
                import java.awt.datatransfer.*
                import java.awt.Toolkit
                cb = Toolkit.getDefaultToolkit().getSystemClipboard();
                data = cb.getContents([]);
                if data.isDataFlavorSupported(DataFlavor.stringFlavor)
                    txt = string(char(data.getTransferData(DataFlavor.stringFlavor)));
                end
            catch
            end
        end
        
        function ensureFITableReady(app, tbl)
            % If target table has no data or wrong shape, initialize it
            if isempty(tbl.Data) || ~istable(tbl.Data) ...
               || height(tbl.Data) ~= numel(app.FIYVals) ...
               || width(tbl.Data)  ~= numel(app.FIXVals)
                app.initFITable(tbl);
            end
        end


        function a1 = rc2a1(~, rc)
            r = rc(1); c = rc(2);
            % convert column number -> Excel letters
            s = "";
            while c > 0
                k = mod(c-1,26);
                s = char('A'+k) + s;
                c = floor((c-1)/26);
            end
            a1 = sprintf('%s%d', s, r);
        end
        
        function PlotFI3DButtonPushed(app, ~)
            % Make sure Table 3 is up to date
            app.updateFITable3();
        
            % Validate data
            if isempty(app.FITbl3) || isempty(app.FITbl3.Data) || ~istable(app.FITbl3.Data)
                uialert(app.UIFigure,'Table 3 is empty. Paste data into Table 1/2 first.','3D Graph');
                return;
            end
            Z = table2array(app.FITbl3.Data);
            if isempty(Z) || all(isnan(Z),'all')
                uialert(app.UIFigure,'Table 3 only has NaNs. Paste valid numbers into Table 1/2.','3D Graph');
                return;
            end
        
            % Build grids
            [X,Y] = meshgrid(app.FIXVals, app.FIYVals);
        
            % New window with a UIAxes
            f = uifigure('Name','FI Table 3 — 3D (% difference)','Position',[100 100 920 680]);
            ax = uiaxes(f,'Position',[60 60 800 560]);
        
            % Plot surface
            surf(ax, X, Y, Z, 'EdgeColor','none');
            grid(ax,'on'); view(ax, 45, 30);
            title(ax, 'FI Table 3 — ((T1 - T2) ./ T1) × 100');
            xlabel(ax, 'X (Throttle)');                 % your X header values (top axis)
            ylabel(ax, 'Y (RPM)');           % your Y axis values (left)
            zlabel(ax, '% difference');
            colorbar(ax);

            % ----- Limit Z axis & color scale -----
            zRange = [-50 50];
            ax.ZLim = zRange;          % limits what's visible on Z
            caxis(ax, zRange);         % match colormap to same range
        end

        function initSpecsheetTable(app, nRows)
    % Build A..P table with grey+read-only protected areas
    if nargin < 2, nRows = 100; end

    nCols = 16; % A..P
    app.SpecColNames = arrayfun(@(k) char('A'+k-1), 1:nCols, 'uni', 0);

    % Strings are convenient for mixed input later
    data = strings(nRows, nCols);

    % Create/attach table if not already created (position set in createComponents)
    if isempty(app.SpecTbl) || ~isvalid(app.SpecTbl)
        app.SpecTbl = uitable(app.SpecsheetTab);
    end

    app.SpecTbl.Data            = data;
    app.SpecTbl.ColumnName      = app.SpecColNames;
    app.SpecTbl.RowName         = (1:nRows).';
    app.SpecTbl.ColumnEditable  = true(1, nCols);
    app.SpecTbl.FontName        = 'Consolas';
    app.SpecTbl.CellEditCallback = createCallbackFcn(app, @SpecTblCellEdit, true);

    % ---- Build protected mask per your rules ----
    prot = false(nRows, nCols);

    % Column A (entire)
    prot(:,1) = true;

    % B5 downward
    if nRows >= 5, prot(5:end, 2) = true; end

    % C5 downward
    if nRows >= 5, prot(5:end, 3) = true; end

    % D1:D5
    rMax = min(5, nRows);
    prot(1:rMax, 4) = true;

    % Entire row 5 (A5:P5)
    if nRows >= 5, prot(5, :) = true; end

    app.SpecProtMask = prot;

    % Style: light grey for protected cells
    delete(findall(app.SpecTbl,'Type','uistyle')); % clear previous styles if re-init
    grey = uistyle('BackgroundColor',[0.92 0.92 0.92]);

    [rIdx, cIdx] = find(prot);
    if ~isempty(rIdx)
        addStyle(app.SpecTbl, grey, 'cell', [rIdx cIdx]);
    end

    % Keep mask handy for the callback
    app.SpecTbl.UserData.protectedMask = prot;
end

function SpecTblCellEdit(app, event)
    % Veto edits only for protected cells; allow elsewhere
    r = event.Indices(1);
    c = event.Indices(2);
    mask = app.SpecTbl.UserData.protectedMask;

    if mask(r,c)
        % Revert to previous value
        D = app.SpecTbl.Data;
        D(r,c) = event.PreviousData;
        app.SpecTbl.Data = D;

        uialert(app.UIFigure, ...
            sprintf('Cell %s%d is read-only.', app.SpecColNames{c}, r), ...
            'Protected Cell', 'Icon','warning');
    end
end


        function makeTile(app,parent,title,icon,tabDest)
            p  = uipanel(parent,'BackgroundColor',[0.11 0.12 0.13],'BorderType','none');
            gl = uigridlayout(p,[3 1], 'RowHeight',{40,'1x',40}, 'Padding',[18 18 18 18]);
        
            % icon (optional)
            try, uiimage(gl,'ImageSource',icon,'ScaleMethod','fit'); catch, uilabel(gl,'Text',''); end
            uilabel(gl,'Text',title,'FontSize',16,'FontWeight','bold', ...
                'HorizontalAlignment','center','FontColor',[0.1 0.1 0.1]);
        
            uibutton(gl,'Text','Open','FontWeight','bold', ...
                'ButtonPushedFcn', @(~,~) set(app.TabGroup,'SelectedTab',tabDest));
        
            % make the whole panel clickable
            p.ButtonDownFcn = @(~,~) set(app.TabGroup,'SelectedTab',tabDest);
        end



        % ==================================================================
        % ================== NEW: FiAi UI / HELPERS ========================
        % ==================================================================

        function buildFiAiUI(app)
            % Main grid in FiAiTab: 3 rows x 2 cols
            gl = uigridlayout(app.FiAiTab,[3 2]);
            gl.RowHeight   = {40, '1x', 'fit'};
            gl.ColumnWidth = {'1x','1x'};
            gl.Padding     = [16 16 16 16];
            gl.RowSpacing  = 10;
            gl.ColumnSpacing = 10;

            % ---- Row 1: top controls
            top = uigridlayout(gl,[1 4]);
            top.Layout.Row = 1; 
            top.Layout.Column = [1 2];
            top.ColumnWidth = {'fit','fit','fit','1x'};
            top.RowHeight   = {'fit'};
            top.Padding     = [0 0 0 0];

            app.FiAiPickFiButton = uibutton(top,'Text','Choose fi.xlsx', ...
                'ButtonPushedFcn', @(~,~)app.pickFiXlsx());
            app.FiAiPickFiButton.Layout.Column = 1;

            app.FiAiPickCsvButton = uibutton(top,'Text','Choose CSV', ...
                'ButtonPushedFcn', @(~,~)app.pickCsvFile());
            app.FiAiPickCsvButton.Layout.Column = 2;

            app.FiAiRunButton = uibutton(top,'Text','Run Program', ...
                'FontWeight','bold', ...
                'ButtonPushedFcn', @(~,~)app.runFiAiProgram());
            app.FiAiRunButton.Layout.Column = 3;

            app.FiAiStatusLabel = uilabel(top,...
                'Text','Idle','FontWeight','bold','FontColor',[0 0.5 0]);
            app.FiAiStatusLabel.HorizontalAlignment = 'right';
            app.FiAiStatusLabel.Layout.Column = 4;

            % ---- Row 2 Col 1: initial fi.xlsx snapshot
            leftPanel = uipanel(gl,'Title','Initial FI (snapshot of fi.xlsx)');
            leftPanel.Layout.Row = 2; 
            leftPanel.Layout.Column = 1;
            leftGrid = uigridlayout(leftPanel,[1 1]);
            leftGrid.RowHeight = {'1x'};
            leftGrid.ColumnWidth = {'1x'};
            leftGrid.Padding = [4 4 4 4];
            app.FiAiInitialTable = uitable(leftGrid);
            app.FiAiInitialTable.Layout.Row = 1;
            app.FiAiInitialTable.Layout.Column = 1;
            app.FiAiInitialTable.ColumnEditable = false;
            app.FiAiInitialTable.RowName = {};

            % ---- Row 2 Col 2: new/updated FI map from Python
            rightPanel = uipanel(gl,'Title','New FI (Python output)');
            rightPanel.Layout.Row = 2; 
            rightPanel.Layout.Column = 2;
            rightGrid = uigridlayout(rightPanel,[1 1]);
            rightGrid.RowHeight = {'1x'};
            rightGrid.ColumnWidth = {'1x'};
            rightGrid.Padding = [4 4 4 4];
            app.FiAiNewTable = uitable(rightGrid);
            app.FiAiNewTable.Layout.Row = 1;
            app.FiAiNewTable.Layout.Column = 1;
            app.FiAiNewTable.ColumnEditable = false;
            app.FiAiNewTable.RowName = {};

            % ---- Row 3 full width: instructions
            app.FiAiNoteLabel = uilabel(gl, ...
                'Text','Steps: Choose fi.xlsx → Choose CSV → Run Program. We snapshot original fi.xlsx and then show the new corrected map from fuel_table_unified_system.xlsx.');
            app.FiAiNoteLabel.Layout.Row = 3; 
            app.FiAiNoteLabel.Layout.Column = [1 2];
            app.FiAiNoteLabel.FontAngle = 'italic';
        end

        function pickFiXlsx(app)
            [f,p] = uigetfile({'*.xlsx','Excel files (*.xlsx)'}, 'Select fi.xlsx');
            if isequal(f,0); return; end
            app.FiXlsxPath = fullfile(string(p), string(f));

            % Load snapshot now and store it
            try
                T = readtable(app.FiXlsxPath, 'TextType','string');
                app.FiInitialSnapshot = T;
                app.showTable(app.FiAiInitialTable, T);
                app.flashStatus("Loaded fi.xlsx snapshot", [0 0.5 0]);
            catch ME
                app.flashStatus("Failed reading fi.xlsx: " + ME.message, [1 0 0]);
            end
        end

        function pickCsvFile(app)
            [f,p] = uigetfile({'*.csv','CSV files (*.csv)'}, 'Select telemetry CSV');
            if isequal(f,0); return; end
            app.DataCsvPath = fullfile(string(p), string(f));
            app.flashStatus("CSV selected: " + f, [0 0.5 0]);
        end

        function showTable(~, tblHandle, T)
            try
                tblHandle.Data = T;
                tblHandle.ColumnName = string(T.Properties.VariableNames);
                tblHandle.ColumnWidth = 'auto';
            catch
                tblHandle.Data = table();
            end
        end

        function flashStatus(app, msg, rgb)
            app.FiAiStatusLabel.Text = msg;
            if nargin>=3
                app.FiAiStatusLabel.FontColor = rgb;
            end
            drawnow;
        end

        function ok = ensureFolders(app)
            ok = true;
            try
                if ~isfolder(app.RawDir); mkdir(app.RawDir); end
                if ~isfolder(app.ProcessedDir); mkdir(app.ProcessedDir); end
            catch ME
                app.flashStatus("Folder error: " + ME.message, [1 0 0]);
                ok = false;
            end
        end

        function copyWithOverwrite(~, src, dst)
            if isfile(dst)
                delete(dst);
            end
            copyfile(src, dst);
        end

        function ok = prepareRawFolder(app)
            % Put chosen fi.xlsx and CSV into data\raw for the Python script
            ok = false;

            if strlength(app.FiXlsxPath)==0 || ~isfile(app.FiXlsxPath)
                app.flashStatus("Choose fi.xlsx first.", [0.8 0.4 0]);
                return;
            end
            if strlength(app.DataCsvPath)==0 || ~isfile(app.DataCsvPath)
                app.flashStatus("Choose CSV first.", [0.8 0.4 0]);
                return;
            end

            if ~app.ensureFolders()
                return;
            end

            try
                % 1) Backup original fi.xlsx snapshot to processed (timestamped)
                if ~isempty(app.FiInitialSnapshot)
                    ts = datestr(now,'yyyymmdd_HHMMSS');
                    backupFile = fullfile(app.ProcessedDir, "fi_original_snapshot_" + ts + ".xlsx");
                    writetable(app.FiInitialSnapshot, backupFile, 'WriteMode','overwritesheet');
                end

                % 2) Clean old CSVs from RAW so auto_detect only sees one
                oldCsvs = dir(fullfile(app.RawDir, '*.csv'));
                for k = 1:numel(oldCsvs)
                    delete(fullfile(oldCsvs(k).folder, oldCsvs(k).name));
                end

                % 3) Copy fi.xlsx and CSV to RAW with canonical names
                canonicalFi = fullfile(app.RawDir, "fi.xlsx");
                canonicalCsv = fullfile(app.RawDir, "telemetry.csv");

                app.copyWithOverwrite(app.FiXlsxPath, canonicalFi);
                app.copyWithOverwrite(app.DataCsvPath, canonicalCsv);

                ok = true;
            catch ME
                app.flashStatus("Prepare RAW failed: " + ME.message, [1 0 0]);
            end
        end

        function runFiAiProgram(app)
            % Full process: snapshot done already, prepare RAW, run python,
            % then load new map into FiAiNewTable
            app.flashStatus("Running...", [0.8 0.4 0]);

            % Make sure we saved the snapshot into FiAiInitialTable (safety)
            if isempty(app.FiInitialSnapshot) || height(app.FiInitialSnapshot)==0
                try
                    if strlength(app.FiXlsxPath)>0 && isfile(app.FiXlsxPath)
                        app.FiInitialSnapshot = readtable(app.FiXlsxPath, 'TextType','string');
                        app.showTable(app.FiAiInitialTable, app.FiInitialSnapshot);
                    end
                catch
                end
            end

            if ~app.prepareRawFolder()
                return;
            end

            try
                % Build system() command:
                cmd = sprintf('cd /d "%s" && "%s" "%s"', ...
                    app.ProjectRoot, app.PyExePath, app.PyScriptPath);

                [exitCode, cmdOut] = system(cmd);

                if exitCode ~= 0
                    app.flashStatus("Python error (see console text)", [1 0 0]);
                    msg = cmdOut;
                    if strlength(msg) > 2000
                        msg = extractAfter(msg, strlength(msg)-2000);
                    end
                    uialert(app.UIFigure, msg, 'Python Error', 'Icon','error');
                    return;
                end

                app.flashStatus("Python OK. Loading output...", [0 0.5 0]);

                % Preferred output file from Python
                outXlsx = fullfile(app.ProcessedDir, "fuel_table_unified_system.xlsx");

                if isfile(outXlsx)
                    try
                        Tnew = readtable(outXlsx, 'TextType','string');
                        app.showTable(app.FiAiNewTable, Tnew);
                        app.flashStatus("Done. New map loaded.", [0 0.5 0]);
                    catch ME
                        app.flashStatus("Output read failed: " + ME.message, [1 0 0]);
                    end
                else
                    % Fallback: if Python didn't generate the unified xlsx,
                    % try showing RAW fi.xlsx as "new"
                    rawFi = fullfile(app.RawDir, "fi.xlsx");
                    if isfile(rawFi)
                        try
                            Tnew = readtable(rawFi, 'TextType','string');
                            app.showTable(app.FiAiNewTable, Tnew);
                            app.flashStatus("No output xlsx; showing RAW fi.xlsx", [0.5 0.5 0]);
                        catch ME
                            app.flashStatus("No output produced. " + ME.message, [1 0 0]);
                        end
                    else
                        app.flashStatus("No output produced (no fuel_table_unified_system.xlsx).", [0.8 0.4 0]);
                    end
                end

            catch ME
                app.flashStatus("MATLAB error: " + ME.message, [1 0 0]);
            end
        end

        % ==================================================================
        % ================= END NEW: FiAi UI / HELPERS =====================
        % ==================================================================

    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function StartupFcn(app)

            % Put Report.xlsx next to the .mlapp file
            pathToMLAPP = fileparts(mfilename('fullpath'));
            app.ReportFile = fullfile(pathToMLAPP,'Report.xlsx');

            % Initialize 3 lists with 20 items each
            app.initChecklistTable(app.UITableChecklist1, app.ItemsPerList);
            app.initChecklistTable(app.UITableChecklist2, app.ItemsPerList);
            app.initChecklistTable(app.UITableChecklist3, app.ItemsPerList);

            app.refreshChecklistRowColors(app.UITableChecklist1);
            app.refreshChecklistRowColors(app.UITableChecklist2);
            app.refreshChecklistRowColors(app.UITableChecklist3);

            % Try to load from the single CSV (if it exists)
            app.ChecklistLoadBtnPush([]);

            app.EBFeature = EBMapFeature(app, app.EBUIAxes, app.EBMapTable, app.EBGearDropDown);

            % --- FI: map the dragged UI components to the helper fields
            app.FITbl1 = app.UITable;    % first (pasteable) table
            app.FITbl2 = app.UITable2;   % second (pasteable) table
            app.FITbl3 = app.UITable3;   % third (computed) table
            
            % Initialize structure/headers
            app.initFITable(app.FITbl1);
            app.initFITable(app.FITbl2);
            app.initFITable(app.FITbl3);
            
            % Make Table 3 read-only (computed)
            nC = numel(app.FIXVals);
            app.FITbl3.ColumnEditable = false(1, nC);
            
            % Recompute once on startup
            app.updateFITable3();
            
            % Hook edit callbacks so Table 3 updates when 1 or 2 changes
            app.FITbl1.CellEditCallback = createCallbackFcn(app, @FITableEdited, true);
            app.FITbl2.CellEditCallback = createCallbackFcn(app, @FITableEdited, true);
            
            % Optional: stack them vertically (top -> bottom)
            app.FITbl1.Position = [7 377 1119 160];
            app.FITbl2.Position = [7 200 1119 160];
            app.FITbl3.Position = [7  20 1119 160];


            % Track selected cell for paste start
            app.UITable.CellSelectionCallback  = createCallbackFcn(app, @FI_SelectTbl1, true);
            app.UITable2.CellSelectionCallback = createCallbackFcn(app, @FI_SelectTbl2, true);
                        
            uibutton(app.FITab, 'Text','Paste → Table 1', ...
                'Position',[250 557 120 23], ...
                'ButtonPushedFcn', @(~,~) app.pasteClipboardIntoTbl(app.UITable, [1 1]));
            
            uibutton(app.FITab, 'Text','Paste → Table 2', ...
                'Position',[380 557 120 23], ...
                'ButtonPushedFcn', @(~,~) app.pasteClipboardIntoTbl(app.UITable2, [1 1]));

            app.FIPlot3DButton = uibutton(app.FITab, 'Text','3D Graph (Table 3)', ...
                'Position',[510 557 140 23], ...
                'ButtonPushedFcn', createCallbackFcn(app, @PlotFI3DButtonPushed, true));

            
            % --- Dashboard tiles on Main tab (no Designer edits) ---
            dash = uigridlayout(app.MainTab,[2 3]);
            dash.RowHeight     = {'1x','1x'};
            dash.ColumnWidth   = {'1x','1x','1x'};
            dash.Padding       = [20 20 20 20];
            dash.RowSpacing    = 16;
            dash.ColumnSpacing = 16;
            
            % Tiles
            app.makeTile(dash,'Engine Brake','gauge.png',app.EngineBrakeTab);
            app.makeTile(dash,'Specsheet','cog.png',app.SpecsheetTab);
            app.makeTile(dash,'FI Tables','graph.png',app.FITab);

            % --- Report UI + initial load ---
            app.buildReportUI();
            % If you want to auto-load the Excel you sent:
            app.loadReportXLSX();
            
            % --- FiAi tab UI ---
            app.buildFiAiUI();
            
            % --- Specsheet table setup (A..P with protected cells) ---
            app.initSpecsheetTable(100);

        end

        % Button pushed function: SaveButton
        function CheckListSaveBtnPushed(app, event)
        app.saveAllChecklistsToSingleCSV();
        end

        % Button pushed function: LoadButton
        function ChecklistLoadBtnPush(app, event)
            app.loadAllChecklistsFromSingleCSV();
        end

        % Cell edit callback: UITableChecklist1
        function ChecklistCellEdit(app, event)
                      tbl = event.Source;     % whichever table fired the event
            if ~isempty(event.Indices) && event.Indices(2) == 1
                % repaint just this row; keep sizes consistent
                nRows = size(tbl.Data,1);
                C = tbl.BackgroundColor;
                if isempty(C) || size(C,1) ~= nRows
                    C = ones(nRows,3);
                end
                r = event.Indices(1);
                if tbl.Data.Checked(r)
                    C(r,:) = [0.7 0.9 1];
                else
                    C(r,:) = [1 1 1];
                end
                tbl.BackgroundColor = C;
            end    
        end

        % Button pushed function: EBLoadCSVButton
        function EBLoadCSVBtnPushed(app, event)
  
        % Create the helper on first use if it's missing/invalid
        if isempty(app.EBFeature) || ~isobject(app.EBFeature) || ~isvalid(app.EBFeature)
            try
                app.EBFeature = EBMapFeature(app, app.EBUIAxes, app.EBMapTable, app.EBGearDropDown);
            catch ME
                uialert(app.UIFigure, "Couldn't create EBMapFeature: " + ME.message, 'Engine Brake');
                return;
            end
        end
    
        % Now safe to call methods on it
        app.EBFeature.loadExcel();


        end

        % Button pushed function: EBAskAssistantButton
        function AskAssistantBtnPushed(app, event)
          
        if strlength(app.EBFile)==0 || isempty(app.EBData)
            uialert(app.UIFigure,'Load a CSV first.','Assistant'); 
            return;
        end
    
        prompt = string(app.EBRequestEditField.Value);
        if isstring(prompt), prompt = strjoin(prompt,newline); end
    
        d = uiprogressdlg(app.UIFigure,'Title','Uploading & analyzing...','Indeterminate','on');
        try
            % Reuse uploaded file if it matches current path; else upload via helper
            if strlength(app.EBFileId)==0 || app.EBUploadedPath ~= app.EBFile
                app.EBFileId = OpenAIHelper.uploadFile(app.EBFile);
                app.EBUploadedPath = app.EBFile;
            end
    
            % Ask via helper
            reply = OpenAIHelper.askAboutFile(app.EBFileId, prompt, app.EBFile);
            app.EBTextArea.Value = splitlines(reply);
    
        catch ME
            app.EBTextArea.Value = splitlines("Error: " + ME.message);
        end
        close(d);

        end

        % Button pushed function: EBSaveXLSXButton
        function EBSaveXLSXButtonPushed(app, event)
            app.EBFeature.saveExcel(); 
        end

        % Value changed function: EBGearDropDown
        function EBGearDropDownValueChanged(app, event)
            value = app.EBGearDropDown.Value;
            app.EBFeature.selectGear(str2double(app.EBGearDropDown.Value));
        end

        % Cell edit callback: EBMapTable
        function EBMapTableCellEdit(app, event)
            % indices = event.Indices;
            % newData = event.NewData;
            app.EBFeature.tableEdited(event);    

        end

        % Button pushed function: FISaveButton
        function FISaveBtnPushed(app, event)
            app.saveFICSV();
        end

        % Button pushed function: FILoadButton
        function FILoadBtnPushed(app, event)
            app.loadFICSV();
        end

        % Button pushed function: EBstatLoadButton
        function ButtonPushedFcn(app, event)
            % Button pushed function: EBstatLoadButton
 
            % Load CSV and plot EB statistics for 4 EB groups.

            [f,p] = uigetfile({'*.csv','CSV files (*.csv)'}, 'Select EB stat CSV');
            if isequal(f,0)
                return; % user cancelled
            end
            fullPath = fullfile(p,f);

            try
                % Read table (first row = headers from the CSV)
                Traw = readtable(fullPath,'TextType','string');

                if height(Traw) < 1
                    uialert(app.UIFigure,'Empty file.','EBstat','Icon','error');
                    return;
                end

                % Limit number of rows so plotting stays fast
                maxRows = min(3000, height(Traw));
                T = Traw(1:maxRows, :);

                % Convert everything to numeric (non-numeric -> NaN)
                nRows = height(T);
                nCols = width(T);
                M = nan(nRows, nCols);

                for c = 1:nCols
                    col = T{:,c};
                    if iscell(col)
                        col = string(col);
                    elseif ~isstring(col)
                        col = string(col);
                    end

                    % decimal comma -> dot
                    col = replace(col, ",", ".");
                    v = str2double(col);     % "AD", "m", "s" -> NaN
                    M(:,c) = v;
                end

                % X axis: use distance if it exists, otherwise row index
                if nCols >= 2
                    x = M(:,2);   % Dist column
                    if all(isnan(x) | x == 0)
                        x = (1:nRows).';
                    end
                    xLabel = 'Distance';
                else
                    x = (1:nRows).';
                    xLabel = 'Row #';
                end

                % Axes and labels
                axArr      = [app.EBstatAxes1, app.EBstatAxes2, ...
                              app.EBstatAxes3, app.EBstatAxes4];
                lineLabels = {'RPM','BP','ebvirt','slip'};

                % Column indices for your X_MM95_Q2.csv layout:
                % Time (1), Dist (2), then 4 groups of 4 columns
                rpmCols  = [3  7 11 15];
                bpCols   = [4  8 12 16];
                ebCols   = [5  9 13 17];
                slipCols = [6 10 14 18];

                for g = 1:4
                    ax = axArr(g);
                    cla(ax);

                    % Safety: check that columns exist
                    if max([rpmCols(g), bpCols(g), ebCols(g), slipCols(g)]) > nCols
                        title(ax, sprintf('Group %d (no data)', g));
                        xlabel(ax, xLabel);
                        ylabel(ax, 'Value');
                        grid(ax,'on');
                        continue;
                    end

                    idxs = [rpmCols(g), bpCols(g), ebCols(g), slipCols(g)];

                    rpm = M(:, idxs(1));
                    bad = isnan(rpm) | rpm == 0;    % hide rows where RPMxEB == 0 / NaN

                    hold(ax,'on');
                    for k = 1:4
                        y = M(:, idxs(k));
                        y(bad) = NaN;               % hide rows where RPM is off
                        if all(isnan(y))
                            continue;
                        end
                        plot(ax, x, y);
                    end
                    hold(ax,'off');

                    grid(ax,'on');
                    xlabel(ax, xLabel);
                    ylabel(ax,'Value');
                    title(ax, sprintf('Group %d', g));
                    legend(ax, lineLabels, 'Location','best');
                    xlim(ax,[min(x(~isnan(x))), max(x(~isnan(x)))]);
                end

            catch ME
                uialert(app.UIFigure, ...
                    "Failed to read/plot CSV: " + ME.message, ...
                    'EBstat','Icon','error');
            end
       

        end

        % ==== NEW: Riders button callback for Report Analysis tab ====
        function RARidersButtonPushed(app, event)
            % Let user choose the riders CSV
            [f,p] = uigetfile({'*.csv','CSV files (*.csv)'}, ...
                              'Select riders CSV');
            if isequal(f,0)
                return; % user cancelled
            end
            fullPath = fullfile(p,f);

            try
                % Read table with strings
                T = readtable(fullPath,'TextType','string');
                vars = string(T.Properties.VariableNames);

                % Ensure position column exists
                if ~any(strcmpi(vars,"position"))
                    uialert(app.UIFigure, ...
                        "Column 'position' not found in CSV.", ...
                        'Riders CSV','Icon','error');
                    return;
                end

                % Find lap time column in seconds
                timeVar = "";
                if any(strcmpi(vars,"best_lap_time"))
                    timeVar = vars(strcmpi(vars,"best_lap_time"));
                elseif any(strcmpi(vars,"best_lap_seconds"))
                    timeVar = vars(strcmpi(vars,"best_lap_seconds"));
                end
                if timeVar == ""
                    uialert(app.UIFigure, ...
                        "No 'best_lap_time' or 'best_lap_seconds' column found.", ...
                        'Riders CSV','Icon','error');
                    return;
                end

                % Normalize to best_lap_time (seconds)
                if timeVar ~= "best_lap_time"
                    T.best_lap_time = T.(timeVar);
                end

                % Sort by position ascending
                T = sortrows(T, 'position');

                % Convert best_lap_time seconds -> 'MM:SS.ss'
                secVals = T.best_lap_time;
                if iscell(secVals)
                    secVals = str2double(string(secVals));
                elseif isstring(secVals)
                    secVals = str2double(secVals);
                else
                    secVals = double(secVals);
                end

                n = numel(secVals);
                lapStr = strings(n,1);
                for i = 1:n
                    v = secVals(i);
                    if isnan(v)
                        lapStr(i) = "";
                    else
                        m = floor(v/60);
                        s = v - 60*m;
                        % format 00:00.00 (MM:SS.ss)
                        lapStr(i) = string(sprintf('%02d:%05.2f', m, s));
                    end
                end
                T.best_lap_time = lapStr;

                % Build subset in requested order
                wanted = {'position','number','name','country','team', ...
                          'best_lap_number','total_laps','best_lap_time'};
                missing = setdiff(wanted, T.Properties.VariableNames);
                if ~isempty(missing)
                    uialert(app.UIFigure, ...
                        "Missing columns: " + strjoin(missing, ', '), ...
                        'Riders CSV','Icon','error');
                    return;
                end

                Sub = T(:, wanted);

                % Display in table
                app.RA_RidersTable.Data = Sub;
                app.RA_RidersTable.ColumnName = { ...
                    'Position','Number','Name','Country','Team', ...
                    'Best lap #','Total laps','Best lap time'};
                app.RA_RidersTable.RowName = {};

            catch ME
                uialert(app.UIFigure, ...
                    "Failed to load/parse CSV: " + ME.message, ...
                    'Riders CSV','Icon','error');
            end
        end

    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1133 632];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.Pointer = 'circle';

            % Create FileMenu
            app.FileMenu = uimenu(app.UIFigure);
            app.FileMenu.Text = 'File';

            % Create Menu_2
            app.Menu_2 = uimenu(app.FileMenu);
            app.Menu_2.Text = 'Menu';

            % Create OptionsMenu
            app.OptionsMenu = uimenu(app.UIFigure);
            app.OptionsMenu.Text = 'Options';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 1 1133 608];

            % Create MainTab
            app.MainTab = uitab(app.TabGroup);
            app.MainTab.Title = 'Main';

            % Create ChecklistTab
            app.ChecklistTab = uitab(app.TabGroup);
            app.ChecklistTab.Title = 'Checklist';

            % Create LoadButton
            app.LoadButton = uibutton(app.ChecklistTab, 'push');
            app.LoadButton.ButtonPushedFcn = createCallbackFcn(app, @ChecklistLoadBtnPush, true);
            app.LoadButton.Position = [3 558 100 22];
            app.LoadButton.Text = 'Load';

            % Create SaveButton
            app.SaveButton = uibutton(app.ChecklistTab, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @CheckListSaveBtnPushed, true);
            app.SaveButton.Position = [106 558 100 22];
            app.SaveButton.Text = 'Save';

            % Create UITableChecklist3
            app.UITableChecklist3 = uitable(app.ChecklistTab);
            app.UITableChecklist3.ColumnName = {'Check'; 'Text'};
            app.UITableChecklist3.ColumnWidth = {50, '1x'};
            app.UITableChecklist3.RowName = {};
            app.UITableChecklist3.ColumnEditable = true;
            app.UITableChecklist3.Position = [7 79 788 157];

            % Create UITableChecklist2
            app.UITableChecklist2 = uitable(app.ChecklistTab);
            app.UITableChecklist2.ColumnName = {'Check'; 'Text'};
            app.UITableChecklist2.ColumnWidth = {50, '1x'};
            app.UITableChecklist2.RowName = {};
            app.UITableChecklist2.ColumnEditable = true;
            app.UITableChecklist2.Position = [377 282 418 252];

            % Create UITableChecklist1
            app.UITableChecklist1 = uitable(app.ChecklistTab);
            app.UITableChecklist1.ColumnName = {'Check'; 'Text'};
            app.UITableChecklist1.ColumnWidth = {50, '1x'};
            app.UITableChecklist1.RowName = {};
            app.UITableChecklist1.ColumnEditable = true;
            app.UITableChecklist1.CellEditCallback = createCallbackFcn(app, @ChecklistCellEdit, true);
            app.UITableChecklist1.Position = [7 282 358 252];

            % Create PreRaceLabel
            app.PreRaceLabel = uilabel(app.ChecklistTab);
            app.PreRaceLabel.FontWeight = 'bold';
            app.PreRaceLabel.Position = [157 537 57 22];
            app.PreRaceLabel.Text = 'Pre-Race';

            % Create PerRiderLabel
            app.PerRiderLabel = uilabel(app.ChecklistTab);
            app.PerRiderLabel.FontWeight = 'bold';
            app.PerRiderLabel.Position = [557 537 58 22];
            app.PerRiderLabel.Text = 'Per Rider';

            % Create GeneralLabel
            app.GeneralLabel = uilabel(app.ChecklistTab);
            app.GeneralLabel.FontWeight = 'bold';
            app.GeneralLabel.Position = [349 247 50 22];
            app.GeneralLabel.Text = 'General';

            % Create EngineBrakeTab
            app.EngineBrakeTab = uitab(app.TabGroup);
            app.EngineBrakeTab.Title = 'Engine Brake';

            % Create EBUIAxesAI
            app.EBUIAxesAI = uiaxes(app.EngineBrakeTab);
            title(app.EBUIAxesAI, 'Title')
            xlabel(app.EBUIAxesAI, 'X')
            ylabel(app.EBUIAxesAI, 'Y')
            zlabel(app.EBUIAxesAI, 'Z')
            app.EBUIAxesAI.Position = [756 20 360 274];

            % Create EBUIAxes
            app.EBUIAxes = uiaxes(app.EngineBrakeTab);
            title(app.EBUIAxes, 'Title')
            xlabel(app.EBUIAxes, 'X')
            ylabel(app.EBUIAxes, 'Y')
            zlabel(app.EBUIAxes, 'Z')
            app.EBUIAxes.Position = [7 235 750 315];

            % Create EBLoadCSVButton
            app.EBLoadCSVButton = uibutton(app.EngineBrakeTab, 'push');
            app.EBLoadCSVButton.ButtonPushedFcn = createCallbackFcn(app, @EBLoadCSVBtnPushed, true);
            app.EBLoadCSVButton.Position = [7 558 100 22];
            app.EBLoadCSVButton.Text = 'Load CSV';

            % Create RequestEditFieldLabel
            app.RequestEditFieldLabel = uilabel(app.EngineBrakeTab);
            app.RequestEditFieldLabel.HorizontalAlignment = 'right';
            app.RequestEditFieldLabel.Position = [930 466 50 22];
            app.RequestEditFieldLabel.Text = 'Request';

            % Create EBRequestEditField
            app.EBRequestEditField = uieditfield(app.EngineBrakeTab, 'text');
            app.EBRequestEditField.Position = [794 441 322 22];

            % Create EBAskAssistantButton
            app.EBAskAssistantButton = uibutton(app.EngineBrakeTab, 'push');
            app.EBAskAssistantButton.ButtonPushedFcn = createCallbackFcn(app, @AskAssistantBtnPushed, true);
            app.EBAskAssistantButton.Position = [905 495 100 22];
            app.EBAskAssistantButton.Text = 'Ask Assistant';

            % Create AnswerLabel
            app.AnswerLabel = uilabel(app.EngineBrakeTab);
            app.AnswerLabel.HorizontalAlignment = 'right';
            app.AnswerLabel.Position = [754 398 25 22];
            app.AnswerLabel.Text = '';

            % Create EBTextArea
            app.EBTextArea = uitextarea(app.EngineBrakeTab);
            app.EBTextArea.Position = [794 312 322 110];

            % Create EBSaveXLSXButton
            app.EBSaveXLSXButton = uibutton(app.EngineBrakeTab, 'push');
            app.EBSaveXLSXButton.ButtonPushedFcn = createCallbackFcn(app, @EBSaveXLSXButtonPushed, true);
            app.EBSaveXLSXButton.Position = [7 214 100 22];
            app.EBSaveXLSXButton.Text = 'Save Excel';

            % Create DropDownLabel
            app.DropDownLabel = uilabel(app.EngineBrakeTab);
            app.DropDownLabel.HorizontalAlignment = 'right';
            app.DropDownLabel.Position = [7 185 65 22];
            app.DropDownLabel.Text = 'Drop Down';

            % Create EBGearDropDown
            app.EBGearDropDown = uidropdown(app.EngineBrakeTab);
            app.EBGearDropDown.Items = {'1', '2', '3', '4', '5', '6'};
            app.EBGearDropDown.ValueChangedFcn = createCallbackFcn(app, @EBGearDropDownValueChanged, true);
            app.EBGearDropDown.Enable = 'off';
            app.EBGearDropDown.Position = [87 185 100 22];
            app.EBGearDropDown.Value = '1';

            % Create EBMapTable
            app.EBMapTable = uitable(app.EngineBrakeTab);
            app.EBMapTable.ColumnName = {'RPM'; '1'; '2'; '3'; '4'; '5'; '6'};
            app.EBMapTable.RowName = {};
            app.EBMapTable.ColumnEditable = true;
            app.EBMapTable.CellEditCallback = createCallbackFcn(app, @EBMapTableCellEdit, true);
            app.EBMapTable.Position = [7 12 734 167];

            % Create SpecsheetTab
            app.SpecsheetTab = uitab(app.TabGroup);
            app.SpecsheetTab.Title = 'Specsheet';

            % Create FITab
            app.FITab = uitab(app.TabGroup);
            app.FITab.Title = 'FI';

            % Create FILoadButton
            app.FILoadButton = uibutton(app.FITab, 'push');
            app.FILoadButton.ButtonPushedFcn = createCallbackFcn(app, @FILoadBtnPushed, true);
            app.FILoadButton.Position = [20 557 100 23];
            app.FILoadButton.Text = 'Load';

            % Create FISaveButton
            app.FISaveButton = uibutton(app.FITab, 'push');
            app.FISaveButton.ButtonPushedFcn = createCallbackFcn(app, @FISaveBtnPushed, true);
            app.FISaveButton.Position = [137 557 100 23];
            app.FISaveButton.Text = 'Save';

            % Create UITable
            app.UITable = uitable(app.FITab);
            app.UITable.ColumnName = {'Column 1'; 'Column 2'; 'Column 3'; 'Column 4'};
            app.UITable.RowName = {};
            app.UITable.Position = [10 282 356 263];

            % Create UITable2
            app.UITable2 = uitable(app.FITab);
            app.UITable2.ColumnName = {'Column 1'; 'Column 2'; 'Column 3'; 'Column 4'};
            app.UITable2.RowName = {};
            app.UITable2.Position = [386 282 356 263];

            % Create UITable3
            app.UITable3 = uitable(app.FITab);
            app.UITable3.ColumnName = {'Column 1'; 'Column 2'; 'Column 3'; 'Column 4'};
            app.UITable3.RowName = {};
            app.UITable3.Position = [761 283 356 263];

            % Create ReportTab
            app.ReportTab = uitab(app.TabGroup);
            app.ReportTab.Title = 'Report';

            % Create FiAiTab
            app.FiAiTab = uitab(app.TabGroup);
            app.FiAiTab.Title = 'FiAi';

            % Create EBstatTab
            app.EBstatTab = uitab(app.TabGroup);
            app.EBstatTab.Title = 'EBstat';

            % Create EBstatAxes1
            app.EBstatAxes1 = uiaxes(app.EBstatTab);
            title(app.EBstatAxes1, 'Title')
            xlabel(app.EBstatAxes1, 'X')
            ylabel(app.EBstatAxes1, 'Y')
            zlabel(app.EBstatAxes1, 'Z')
            app.EBstatAxes1.Position = [21 293 511 245];

            % Create EBstatAxes2
            app.EBstatAxes2 = uiaxes(app.EBstatTab);
            title(app.EBstatAxes2, 'Title')
            xlabel(app.EBstatAxes2, 'X')
            ylabel(app.EBstatAxes2, 'Y')
            zlabel(app.EBstatAxes2, 'Z')
            app.EBstatAxes2.Position = [557 293 561 252];

            % Create EBstatAxes3
            app.EBstatAxes3 = uiaxes(app.EBstatTab);
            title(app.EBstatAxes3, 'Title')
            xlabel(app.EBstatAxes3, 'X')
            ylabel(app.EBstatAxes3, 'Y')
            zlabel(app.EBstatAxes3, 'Z')
            app.EBstatAxes3.Position = [22 20 510 264];

            % Create EBstatAxes4
            app.EBstatAxes4 = uiaxes(app.EBstatTab);
            title(app.EBstatAxes4, 'Title')
            xlabel(app.EBstatAxes4, 'X')
            ylabel(app.EBstatAxes4, 'Y')
            zlabel(app.EBstatAxes4, 'Z')
            app.EBstatAxes4.Position = [557 28 549 255];

            % Create EBstatLoadButton
            app.EBstatLoadButton = uibutton(app.EBstatTab, 'push');
            app.EBstatLoadButton.ButtonPushedFcn = createCallbackFcn(app, @ButtonPushedFcn, true);
            app.EBstatLoadButton.Position = [21 549 100 23];
            app.EBstatLoadButton.Text = 'Load CSV';

            % ==== NEW: ReportAnalysisTab and controls ====
            app.ReportAnalysisTab = uitab(app.TabGroup);
            app.ReportAnalysisTab.Title = 'Report Analysis';

            % Riders button
            app.RA_RidersButton = uibutton(app.ReportAnalysisTab, 'push');
            app.RA_RidersButton.Position = [20 560 100 23];
            app.RA_RidersButton.Text = 'Riders';
            app.RA_RidersButton.ButtonPushedFcn = ...
                createCallbackFcn(app, @RARidersButtonPushed, true);

            % Laps button (callback to be added later)
            app.RA_LapsButton = uibutton(app.ReportAnalysisTab, 'push');
            app.RA_LapsButton.Position = [130 560 100 23];
            app.RA_LapsButton.Text = 'Laps';

            % Sectors button (callback to be added later)
            app.RA_SectorsButton = uibutton(app.ReportAnalysisTab, 'push');
            app.RA_SectorsButton.Position = [240 560 100 23];
            app.RA_SectorsButton.Text = 'Sectors';

            % Riders table
            app.RA_RidersTable = uitable(app.ReportAnalysisTab);
            app.RA_RidersTable.Position = [20 20 1090 520];
            app.RA_RidersTable.RowName = {};
            app.RA_RidersTable.ColumnEditable = false;

            % Create IIMPULSERACINGDANIELDELCERROTURNERLabel
            app.IIMPULSERACINGDANIELDELCERROTURNERLabel = uilabel(app.UIFigure);
            app.IIMPULSERACINGDANIELDELCERROTURNERLabel.BackgroundColor = [0.902 0.902 0.902];
            app.IIMPULSERACINGDANIELDELCERROTURNERLabel.HorizontalAlignment = 'center';
            app.IIMPULSERACINGDANIELDELCERROTURNERLabel.FontSize = 18;
            app.IIMPULSERACINGDANIELDELCERROTURNERLabel.FontWeight = 'bold';
            app.IIMPULSERACINGDANIELDELCERROTURNERLabel.FontColor = [0.1137 0.5098 0.6784];
            app.IIMPULSERACINGDANIELDELCERROTURNERLabel.Position = [1 610 1132 23];
            app.IIMPULSERACINGDANIELDELCERROTURNERLabel.Text = 'IIMPULSE RACING                                         ©DANIEL DEL CERRO TURNER';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = mainii

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
