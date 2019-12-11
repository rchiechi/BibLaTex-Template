%% Class rcclab
%% Adapted from the nature class https://www.ctan.org/tex-archive/macros/latex/contrib/nature/
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{rcclab}[11/12/2019 v1.0]
\typeout{A class for writing RCCLab manuscripts}
\typeout{Written by Ryan Chiechi}
\typeout{ }

\LoadClass[12pt]{article}
\RequirePackage{stix} % Super nice science font
\RequirePackage{fullpage} % Non-stupid layout
\RequirePackage{graphicx} % Figures
\RequirePackage[version=4]{mhchem} % Formula subscripts using \ce{}
\RequirePackage{xcolor} % For colored text
\RequirePackage[separate-uncertainty=true]{siunitx} % Enables \SI{} for units
\RequirePackage[utf8]{inputenc} % Needed to render UTF8 characters
\RequirePackage{subfig} % For sub figures because some people like them for some reason
\RequirePackage{xr} % For cross-referencing figures
\RequirePackage{hyperref} % Hyperlinks
\RequirePackage{ifthen}
\RequirePackage{kvoptions}
\SetupKeyvalOptions{%
   family=rcclab,
   prefix=rcclab@,
   % setkeys=\kvsetkeys,
   }

\DeclareStringOption[chem-acs]{bibstyle}[chem-acs]
\DeclareBoolOption[false]{suppinfo}
\ProcessKeyvalOptions{rcclab}
\PassOptionsToPackage{style=\rcclab@bibstyle}{biblatex}
\RequirePackage{biblatex} % For BibLaTeX referencing

%% Some style parameters
\setlength{\parindent}{0.39in}
\setlength{\parskip}{18pt}
\newcommand{\spacing}[1]{\renewcommand{\baselinestretch}{#1}\large\normalsize}
\spacing{2}

\ifrcclab@suppinfo
  \def\thepage{S-\arabic{page}}
  \renewcommand*\thefigure{S\@arabic\c@figure}
  \renewcommand*\thetable{S\@arabic\c@table}
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
    \setcounter{enumi}{1}%
    \setlength{\parindent}{0in}%
    \slshape\sloppy%
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

% Redefine the abstract environment to be the first centered paragraph
\renewenvironment{abstract}{%
    \setlength{\parindent}{0in}%
    \setlength{\parskip}{0in}%
    \centering%
    }{\par\vspace{-6pt}}


%% Redefine the \section command.
\renewcommand{\section}{\@startsection {section}{1}{0pt}%
    {-6pt}{1pt}%
    {\bfseries}%
    }
\renewcommand{\subsection}{\@startsection {subsection}{2}{0pt}%
    {-0pt}{-0.5em}%
    {\bfseries}*%
    }

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
