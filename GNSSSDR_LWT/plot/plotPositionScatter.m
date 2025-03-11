function plotPositionScatter(matFilePath, SaveErrPosPng)
    % Load .mat file
    data = load(matFilePath);
    usrPos = data.navSolutionsCT.usrPosENU;
    localTime = data.navSolutionsCT.localTime;

    % calculation the difference relative to the true coordinates
    deltaX = usrPos(:, 1);
    deltaY = usrPos(:, 2);

    % Normalize time to generate color map
%     normalizedTime = (localTime - min(localTime)) / (max(localTime) - min(localTime));

    % Plot scatter diagram
    figure;
    scatter(deltaX, deltaY, 40, localTime, 'filled');
    blue = [linspace(0, 1, 256)' zeros(256, 1) ones(256, 1)];  % generate a colormap from black to blue
    colormap(flipud(blue));  % Reverse the colormap
    colorbar;
    xlabel('\DeltaX (X - X0)');
    ylabel('\DeltaY (Y - Y0)');
    title('Prediction Coordinate Error');
    grid on;

    % set the origin of the axes
    ax = gca;
    ax.XAxisLocation = 'origin';
    ax.YAxisLocation = 'origin';
    legend('localtime')

    % save the image
    if nargin > 3 && ~isempty(SaveErrPosPng)
        saveas(gcf, SaveErrPosPng);
    end
end