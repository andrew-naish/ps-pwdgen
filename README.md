# ps-pwdgen
Powershell Password Generator

## Parameters
 - **PasswordMask**: (Default: {wl:colours}{wl:random}#{int}) You can add any charecter before, in between or after placeholders.
 - **WordlistDirectory**: (Default: .\wordlists) Where the wordlists can be found.
 - **Count**: (Default: 1) How many password(s) to generate.
 - **NoInfo**: (Default: false) Whether or not to display info about the mask and wordlists used to the console.

### Pasword mask options
 - **{wl:random}** - A random word from a random wordlist. If used more than once, more than 1 wordlist will be used.  
 - **{int}** - An integer between 1000 and 9999.  
 - **{vowel_lower}** - A.. vowel.  
 - **{consonant_lower}** - Aaaand a consonent.  
 - **{vowel_upper}** - Uppercase vowel.  
 - **{consonant_upper}** - Uppercase consonent.  

#### Use a specific wordlist
If you'd like to include a word from a specific wordlist in your password use {wl:<wordlist_name>}.
Replace `<wordlist_name>` with the name of the .txt file in the wordlist directory. 

## Usage
`.\generate.ps1` Create 1 password with the default parameters.

### More examples

**Generate 3 jibberish, but pronouncable passwords**  
`.\generate.ps1 -PasswordMask "{consonant_upper}{vowel_lower}{vowel_lower}{consonant_lower}{vowel_lower}{int}" -Count 3`
>Generating passwords using pattern: {consonant_upper}{vowel_lower}{vowel_lower}{consonant_lower}{vowel_lower}{int}  
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
