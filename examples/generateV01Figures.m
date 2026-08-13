%GENERATEV01FIGURES Reproduce the selected V0.1 documentation figures.
%   Run from any working directory with:
%   matlab -batch "run('examples/generateV01Figures.m')"

generatorFilePath = mfilename('fullpath');
repositoryRoot = fileparts(fileparts(generatorFilePath));
run(fullfile(repositoryRoot, 'examples', 'runBasicLMSExample.m'));

assetDirectory = fullfile(repositoryRoot, 'docs', 'assets');
if ~isfolder(assetDirectory)
    mkdir(assetDirectory);
end

geometryFigure = figure('Visible', 'off', 'Color', 'white', ...
    'Position', [100, 100, 900, 650]);
geometryHandles = micloc.plotLocalizationGeometry( ...
    basicLMSResult, axes(geometryFigure));
axis(geometryHandles.axes, 'padded');
applyDocumentationTheme(geometryFigure);
exportgraphics(geometryFigure, fullfile(assetDirectory, ...
    'v0.1-localization-geometry.png'), 'Resolution', 160);
close(geometryFigure);

tdoaFigure = figure('Visible', 'off', 'Color', 'white', ...
    'Position', [100, 100, 900, 600]);
micloc.plotTDOAComparison(basicLMSResult, axes(tdoaFigure));
applyDocumentationTheme(tdoaFigure);
exportgraphics(tdoaFigure, fullfile(assetDirectory, ...
    'v0.1-tdoa-comparison.png'), 'Resolution', 160);
close(tdoaFigure);

lmsFigure = figure('Visible', 'off', 'Color', 'white', ...
    'Position', [100, 100, 900, 750]);
micloc.plotLMSDiagnostics(basicLMSResult, 4, lmsFigure);
applyDocumentationTheme(lmsFigure);
exportgraphics(lmsFigure, fullfile(assetDirectory, ...
    'v0.1-lms-diagnostics.png'), 'Resolution', 160);
close(lmsFigure);

fprintf('Selected V0.1 figures written to %s\n', assetDirectory);

function applyDocumentationTheme(figureHandle)
darkText = [0.15, 0.15, 0.15];
axesHandles = findall(figureHandle, 'Type', 'axes');
for axesIndex = 1:numel(axesHandles)
    currentAxes = axesHandles(axesIndex);
    currentAxes.Color = 'white';
    currentAxes.XColor = darkText;
    currentAxes.YColor = darkText;
    currentAxes.GridColor = [0.65, 0.65, 0.65];
    currentAxes.MinorGridColor = [0.8, 0.8, 0.8];
    currentAxes.Title.Color = darkText;
    currentAxes.XLabel.Color = darkText;
    currentAxes.YLabel.Color = darkText;
end
legendHandles = findall(figureHandle, 'Type', 'legend');
set(legendHandles, 'Color', 'white', 'TextColor', darkText, ...
    'EdgeColor', [0.45, 0.45, 0.45]);
end
