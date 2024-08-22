local printer = [[ __            _                     ___ _                 _ 
/ _\ ___ _ __ | |_ _   _ _ __ __ _  / __\ | ___  _   _  __| |
\ \ / _ \ '_ \| __| | | | '__/ _` |/ /  | |/ _ \| | | |/ _` |
_\ \  __/ | | | |_| |_| | | | (_| / /___| | (_) | |_| | (_| |
\__/\___|_| |_|\__|\__,_|_|  \__,_\____/|_|\___/ \__,_|\__,_|]]

-- Function to print blank lines
function printBlankLines(count)
    for i = 1, count do
        print('')
    end
end

-- Event handler for resource start
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Citizen.Wait(1700)
        -- Print 50 blank lines to simulate clearing the console
        printBlankLines(35)

        -- Print the server started message
        print(printer)
        printBlankLines(1)
        print('[Sentura.cloud] Server has been started.')
    end
end)