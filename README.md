# ps-pwdgen
Powershell Password Generator

## Parameters
 - **PasswordMask**: (Default: {word}#{integer}) You can add any charecter before, in between or after placeholders.
 - **WordlistDirectory**: (Default: .\wordlists) Where the wordlists can be found.
 - **Count**: (Default: 1) How many password(s) to generate.
 - **NoInfo**: (Default: false) Whether or not to display info about the mask and wordlists used to the console.

### Pasword mask options
 - **{word}** - A random word from a random wordlist. If used more than once, more than 1 wordlist will be used.  
 - **{seperator}** - '@' or '#' *might remove this*   
 - **{int}** - An integer between 1000 and 9999.  
 - **{vowel}** - A.. vowel.  
 - **{conso}** - Aaaand a consonent.  
 - **{vowelUpper}** - Uppercase vowel.  
 - **{consoUpper}** - Uppercase consonent.  

## Usage
`.\generate.ps1` Create 1 password with the default parameters.

### More examples

**Generate 3 jibberish, but pronouncable passwords**  
`.\generate.ps1 -PasswordMask "{consoUpper}{vowel}{vowel}{conso}{vowel}{int}" -Count 3`
>Generating passwords using pattern: {consoUpper}{vowel}{vowel}{conso}{vowel}{int}  
Juigu1809  
Foohi6971  
Hoese1874

**Generate 3 passwords without the fluff**  
`.\generate.ps1 -Count 3 -NoInfo`
>Astana#2854  
Dublin#6577  
London#2887  

## TODO
 - Make Get-Random more **random!!**
 - Add '-ToClip' parameter
