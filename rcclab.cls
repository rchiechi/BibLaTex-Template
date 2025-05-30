%% Class rcclab
%% Adapted from the nature class https://www.ctan.org/tex-archive/macros/latex/contrib/nature/
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{rcclab}[2024-6-17 v1.2]
\typeout{A class for writing RCCLab manuscripts}
\typeout{Written by Ryan Chiechi}
\typeout{ }

\LoadClass[12pt]{article}
\RequirePackage{setspace}
\RequirePackage{fullpage} % Non-stupid layout
\RequirePackage{graphicx} % Figures
\RequirePackage{float} % So we can force figures to appear in the rigth place
\RequirePackage[version=4]{mhchem} % Formula subscripts using \ce{}
\RequirePackage{xcolor} % For colored text
\RequirePackage{siunitx} % Enables \SI{} for units
\RequirePackage[utf8]{inputenc} % Needed to render UTF8 characters
\RequirePackage{subfig} % For sub figures because some people like them for some reason
\RequirePackage{xr} % For cross-referencing figures
\RequirePackage{hyperref} % Hyperlinks
\RequirePackage{ifthen}
\RequirePackage{kvoptions}
\RequirePackage{booktabs}
\RequirePackage[capitalize]{cleveref}
\SetupKeyvalOptions{%
 family=rcclab,
 prefix=rcclab@,
 % setkeys=\kvsetkeys,
}

\DeclareStringOption[chem-acs]{bibstyle}[chem-acs]
\DeclareBoolOption[false]{noarticletitle}
\DeclareStringOption[false]{articledoi}[false]
\DeclareStringOption[false]{articleurl}[false]
\DeclareStringOption[100]{maxauthors}[100]
\DeclareBoolOption[false]{suppinfo}
\DeclareBoolOption[false]{numberedsubsections}
\DeclareBoolOption[false]{stixfont}
\ProcessKeyvalOptions{rcclab}

\ifrcclab@stixfont
 \RequirePackage{stix2} % Super nice science font
\fi

\usepackage{etoolbox}

\PassOptionsToPackage{style=\rcclab@bibstyle,
doi=\rcclab@articledoi,
url=\rcclab@articleurl,
maxbibnames=\rcclab@maxauthors,
articletitle=\ifbool{rcclab@noarticletitle}{false}{true}}{biblatex}

\RequirePackage{biblatex} % For BibLaTeX referencing

%% Some style parameters

\captionsetup{justification=justified,%
 font={md,singlespacing},%
 labelfont=bf%
}

\setlength{\parindent}{0.39in}
\setlength{\parskip}{18pt}
\renewcommand{\spacing}[1]{\renewcommand{\baselinestretch}{#1}\large\normalsize}
\spacing{2}


\ifrcclab@suppinfo
 \def\thepage{S-\arabic{page}}
 \renewcommand*\thefigure{S\@arabic\c@figure}
 \renewcommand*\thetable{S\@arabic\c@table}
 \renewcommand*\thesection{S\@arabic\c@section}
 \renewcommand{\theequation}{S\arabic{equation}}
 \newcommand{\@siprefix}{Supporting Information for: }
\else
 \newcommand{\@siprefix}{}
\fi


%% Redefine \maketitle for RCCLab style
\def\@maketitle{%
 \newpage\spacing{1}\setlength{\parskip}{12pt}%
 {\Large\bfseries\noindent\sloppy \@siprefix \textsf{\@title} \par}%
 {\noindent\sloppy \@author}%
}

%% Define the affiliations environment, list each institution as an \item
%% Put after \maketitle
\newenvironment{affiliations}{%
 \renewcommand{\baselinestretch}{1}
 \setcounter{enumi}{1}%
 \setlength{\parindent}{0in}%
 %\slshape\sloppy
  \normalfont\sloppy
 \begin{list}{\upshape$^{\arabic{enumi}}$}{%
  \usecounter{enumi}%
  \setlength{\leftmargin}{0in}%
  \setlength{\topsep}{0in}%
  \setlength{\labelsep}{0in}%
  \setlength{\labelwidth}{0in}%
  \setlength{\listparindent}{0in}%
  \setlength{\itemsep}{0ex}%
        \setlength{\parsep}{0in}%
        }
        }{\end{list}\par\vspace{12pt}}

%% Itemize list for outlining
\newenvironment{outline}{%
 \renewcommand{\baselinestretch}{1}
 \setlength{\parindent}{0in}%
 \normalfont%
 \begin{itemize}{}{}%
  }{\end{itemize}}

% Redefine the abstract environment to be the first centered paragraph
\renewenvironment{abstract}{%
 \renewcommand{\baselinestretch}{1}%
 \textbf{Abstract}%
 \setlength{\parindent}{0in}%
 \setlength{\parskip}{0in}%
 \centering%
}{\par\vspace{-6pt}}

\ifrcclab@suppinfo
\else
%% Redefine the \section command.
\renewcommand{\section}{\@startsection {section}{1}{0pt}%
 {-6pt}{1pt}%
 {\bfseries}%
}
\ifrcclab@numberedsubsections
\renewcommand{\subsection}{\@startsection {subsection}{2}{0pt}%
 {-0pt}{-0.5em}%
 {\bfseries}%
}
\else
\renewcommand{\subsection}{\@startsection {subsection}{2}{0pt}%
 {-0pt}{-0.5em}%
 {\bfseries}*%
}
\fi
\fi

%% Define the methods environment.  Use \subsection to separate.
\newenvironment{methods}{%
 \section*{Methods}%
 \setlength{\parskip}{12pt}%
}{}

%% Define the experimental environment.  Use \subsection to separate.
\newenvironment{experimental}{%
 \section*{Experimental}%
 \setlength{\parskip}{12pt}%
}{}

% Setup SI units pacakge for \SI, \si and \SIrange commands
\sisetup{mode = match}
\sisetup{propagate-math-font = true}
\sisetup{uncertainty-mode = separate}
\sisetup{range-units = single}

%% Provide some common macros
\DeclareCiteCommand{\citenum}
  {}
  {\printfield{labelnumber}}
  {}
  {}

%% Dispersity symbol (\Dbar)
\ProvideTextCommand{\Dbar}{OT1}{\raisebox{0.25ex}{-}\kern-0.4em D}

\newcommand{\red}[1]{\textcolor{red}{#1}}%
\newcommand{\blue}[1]{\textcolor{blue}{#1}}%
\newcommand{\green}[1]{\textcolor{green}{#1}}%

\newcommand*{\ie}{\textit{i.e.}, }%
\newcommand*{\eg}{\textit{e.g.}, }%
\newcommand*{\et}{\textit{et al}.}%

\newcommand*{\ts}[1]{$\mathrm{#1}^{\mathrm{TS}}$}%
\newcommand*{\mica}[1]{$\mathrm{#1}^{\mathrm{Mica}}$}%
\newcommand*{\afm}[1]{$\mathrm{#1}^{\mathrm{AFM}}$}%
\newcommand*{\cp}[1]{$\mathrm{#1}^{\mathrm{AFM}}$}%

\newcommand*{\Mn}{$M_\mathrm{n}$}
\newcommand*{\Mw}{$M_\mathrm{w}$}

\newcommand*{\fermi}{E_\mathrm{F}} % Use inside math
\newcommand*{\egap}{E_\mathrm{g}} % Use inside math
\newcommand*{\Junits}{\si{Acm^{-2}}}%
\newcommand*{\logJ}{$\log|J|$}%
\newcommand*{\logI}{$\log|I|$}%
\newcommand*{\vtrans}{$V_{\mathrm{trans}}$}%
\newcommand*{\vtransp}[1]{$V_{\mathrm{trans}}^{(#1)}$}%
\newcommand*{\vtransmm}[1]{V_{\mathrm{trans}(#1)}}%
\newcommand*{\degC}[1]{\SI{#1}{\celsius}}%


% Chemistry Units
\DeclareSIPrefix{\micro}{\text{\textmu}}{-6}
\DeclareSIUnit\molar{\mole\per\cubic\deci\metre}
\DeclareSIUnit\Molar{\textsc{M}}
\DeclareSIUnit\torr{torr}
\DeclareSIUnit\calorie{cal}
\DeclareSIUnit\debye{D}
\DeclareSIUnit\angstrom{\protect \text  {Å}}
