-- Folder action for ~/Downloads: hands new items to ses-bolucu-unzip.sh.
on adding folder items to thisFolder after receiving addedItems
	do shell script "/bin/zsh " & quoted form of (POSIX path of (path to home folder) & "Library/Scripts/ses-bolucu-unzip.sh") & " " & quoted form of (POSIX path of thisFolder)
end adding folder items to
