local fenv = getfenv(0);
fenv.inspect = rawget(require('libs/inspect/inspect'), 'inspect');
ui_imgui.SetClipboardText(inspect(fenv, {
    newline = '\n',
    indent = '    '
}));
