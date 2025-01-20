# Package Load and Read in Data

#taylor packages
#library(tidyverse) 
#library(wooldridge)

#shruti & taylor packages
library(kableExtra)
library(modelsummary)
library(dplyr)
library(car)
library(lmtest)
library(sandwich)
library(stargazer)
library(caret)
library(moments)
library(psych)
library(magrittr)  
library(knitr)
library(patchwork)
library(stargazer)
library(scales)
library(gridExtra)
library(grid)


set.seed(123)

# Taylor's Path
#input_data <- read.csv("~/w203/w203_lab2/data/raw/pppub23.csv")
#hh_house <- read.csv("~/w203/w203_lab2/data/raw/hhpub23.csv")

# Shruti's Path
# input_data <- read.csv("/home/rstudio/kitematic/asecpub23csv/pppub23.csv")
# hh_house <- read.csv("/home/rstudio/kitematic/asecpub23csv/hhpub23.csv")

# Alec's Path
input_data <- read.csv("/Users/alecnaidoo/Downloads/asecpub23csv/pppub23.csv")
hh_house <- read.csv("/Users/alecnaidoo/Downloads/asecpub23csv/hhpub23.csv")
input_data <- input_data %>% 
  left_join(hh_house, by = c("PH_SEQ" = "H_SEQ"))

# Wrangle Input Data
persons_snap_df <- input_data %>%
  filter(!A_AGE %in% c(85, 80)) %>%
  filter(SPM_HEAD == 1) %>%
  filter(SPM_SNAPSUB > 0) %>%
  filter(!SS_YN == 0) %>% # This doesn't end up removing
  mutate(A_SEX = as.factor(A_SEX)) %>%
  mutate(MALE = case_when(A_SEX == 1 ~ "1",
                          A_SEX == 2 ~ "0")) %>%
  mutate(IS_HISPANIC = case_when(PEHSPNON == 1 ~ "1",
                                 PEHSPNON == 2 ~ "0",)) %>%
  mutate(DEGREE = case_when(
    A_HGA %in% c(0, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40) ~ "0",
    A_HGA %in% c(41, 42, 43, 44, 45, 46) ~ "1"
  )) %>%
  mutate(RENTER = case_when(SPM_TENMORTSTATUS == 3  ~ "1",
                            SPM_TENMORTSTATUS %in% c(1, 2)  ~ "0")) %>%
  mutate(IS_DISABLED = case_when(DIS_HP == 1 ~ "1",
                                 DIS_HP == 2 ~ "0")) %>%
  mutate(
    RACE = case_when(
      IS_HISPANIC == "1" &
        PRDTRACE %in% c(1, 2, 3, 4, 5) ~ "Hispanic only",
      PRDTRACE %in% c(1) ~ "White only",
      PRDTRACE %in% c(2) ~ "Black only",
      PRDTRACE %in% c(3) ~ "American Indian/Alaskan Native only",
      PRDTRACE %in% c(4) ~ "Asian only",
      PRDTRACE %in% c(5) ~ "Hawaiian/Pacific Islander only",
      TRUE ~ "Mixed"
    )
  ) %>%
  mutate(NOT_IN_LABOR_FORCE = case_when(PEMLR %in% c(1, 2, 3, 4) ~ "0",
                                        PEMLR %in% c(5, 6, 7) ~ "1",)) %>%
  filter(!PEMLR == 0) %>% # Drops 5 records
  mutate(NOT_RECEIVE_SS_INCOME = case_when(SS_YN == 1 ~ "0",
                                       SS_YN == 2 ~ "1")) %>%
  filter(!GESTFIPS %in% c(02, 15)) %>% #taking out hawaii and alaska (removes 147 observations)
  mutate(SPM_WCOHABIT = as.character(SPM_WCOHABIT)) %>%
  strings2factors() %>%
  select(
    SPM_SNAPSUB,
    A_AGE,
    SPM_NUMKIDS,
    SPM_NUMADULTS,
    RENTER,
    NOT_IN_LABOR_FORCE,
    SPM_WCOHABIT,
    RACE,
    MALE,
    DEGREE,
    NOT_RECEIVE_SS_INCOME
  )

# Create Exploration Set 
exploration_size <- floor(0.3 * nrow(persons_snap_df))

exploration_index <- sample(seq_len(nrow(persons_snap_df)), size = exploration_size)

persons_snap_exploration_df <- persons_snap_df[exploration_index,] 

# Create confirmation set
persons_snap_df <- persons_snap_df[-exploration_index,]


# Function Read in 

plot_model_residuals <- function(model, data, response_var) {
  model_res <- resid(model)
  
  data <- data %>%
    mutate(Residuals = model_res)
  
  ggplot(data, aes_string(x = response_var, y = "Residuals")) +
    geom_point(alpha = 0.3) +
    geom_smooth(se = FALSE) +
    theme_minimal() +
    labs(x = paste("Value of", response_var), y = "Residuals", title = "Model Residuals")
}

# Function for Sig Code 
get_signif_codes <- function(p_value) {
  if (p_value < 0.001) {
    return("***")
  } else if (p_value < 0.01) {
    return("**")
  } else if (p_value < 0.05) {
    return("*")
  } else if (p_value < 0.1) {
    return(".")
  } else {
    return("")
  }
}

get_coef <- function(modname, varname) {
  est <- round(summary(modname)$coefficients[varname, "Estimate"], digits = 2)
  p_val <- summary(modname)$coefficients[varname, "Pr(>|t|)"]
  signif_code <- get_signif_codes(p_val)
  return(paste0(est, signif_code))
}
