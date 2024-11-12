# Global imports
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import datetime as dt
import re

# Loading data
df_initial_data = pd.read_excel('./data_sources/Dataset Task 1.xlsx')

# Data cleanup
def clean_df(df):
    def clean_text(string):
        # Remove all characters that are not letters, numbers, or spaces
        cleaned_string = re.sub(r'[^\s\sA-Za-z0-9_]+', '', string)
        # Strip leading and trailing spaces and tabulations
        cleaned_string = cleaned_string.strip()
        cleaned_string = cleaned_string.capitalize()
        return cleaned_string

    def clean_column_name(name):
        # Delete all info in brackets and replace spaces with underscores
        name_no_brackets = re.sub(r'\[.*?\]', '', name)
        name_num_corrected = re.sub(r'#', 'num', name_no_brackets)
        name_normalized = re.sub(r'\s+', '_', name_num_corrected)
        # Apply clean_text to the column name
        cleaned_name = clean_text(name_normalized)
        # Ensure lowercase for consistency
        return cleaned_name.lower()

    # Clean and normalize column names first
    df.columns = [clean_column_name(col) for col in df.columns]

    for col in df.columns:
        # Determine if the column is string type
        if df[col].dtype == 'object':
            # Replace null values with empty string for string columns
            df[col] = df[col].fillna('')
            df[col] = df[col].apply(lambda x: clean_text(x) if isinstance(x, str) else x)
        else:
            # Determine if the column is numerical (float or int)
            if np.issubdtype(df[col].dtype, np.number):
                # Replace null values with 0 for numerical columns
                df[col] = df[col].fillna(0)
                
    return df

df_clean = clean_df(df_initial_data.copy())

# Assigning additional data
df_clean['date'] = pd.to_datetime(df_clean['time'])
df_clean['day_name'] = df_clean['time'].dt.day_name()
df_clean['weekday'] = df_clean['time'].dt.dayofweek + 1
df_clean['day_of_month'] = df_clean['time'].dt.day

df_clean['revenue_before_discount'] = df_clean['price_before_discount_includ_vat_eur'] * df_clean['num_of_sold_sku_items']
df_clean['revenue_after_discount'] = (df_clean['price_before_discount_includ_vat_eur'] - df_clean['discount_value_eur']) * df_clean['num_of_sold_sku_items']
df_clean['profit_before_waste'] = df_clean['revenue_after_discount'] - (df_clean['item_cogs_net_vat_eur'] * df_clean['num_of_sold_sku_items'])
df_clean['waste_cogs'] = df_clean['waste_num_of_items'] * df_clean['item_cogs_net_vat_eur']
df_clean['profit_after_waste'] = df_clean['profit_before_waste'] - df_clean['waste_cogs']

# Slicing the product data
df_products = df_clean[df_clean['category_level_1'] != 'Save me']

# Setting style parameters
palette = sns.color_palette('Spectral', 5)
palette.reverse()
sns.set_theme(style='white', palette=palette)
palette

# Helper functions
def visualize_weekly_numbers(
        df, 
        category, 
        show_by="percentage", 
        metrics=['revenue_before_discount', 'revenue_after_discount'],
        y_label='Revenue'
    ):
    df_revenue_by_category = (
        df
        .groupby(['date', category])
        .agg(
            {metric: 'sum' for metric in metrics}  # Dynamically aggregate based on the provided metrics
        )
        .reset_index()
    )

    weekly_total_revenue = (
        df_revenue_by_category
        .groupby('date')
        .agg(
            {metric: 'sum' for metric in metrics}  # Sum weekly for total revenue by metric
        )
        .resample('W').sum()
    )

    df_revenue_by_category.set_index('date', inplace=True)
    df_revenue_by_category_weekly = df_revenue_by_category.groupby(category).resample('W').sum().reset_index()

    # Merge and calculate percentages
    df_revenue_percentage = pd.merge(df_revenue_by_category_weekly, weekly_total_revenue, left_on='date', right_index=True, suffixes=('', '_total'))
    for metric in metrics:
        df_revenue_percentage[f'{metric}_pct'] = df_revenue_percentage[metric] / df_revenue_percentage[f'{metric}_total'] * 100

    if show_by == "percentage":
        avg_values = df_revenue_percentage.groupby(category).mean().mean(axis=1)  # Mean of percentages
        data_column_suffix = '_pct'
    else:
        avg_values = df_revenue_by_category_weekly.groupby(category).sum().mean(axis=1)  # Mean of absolute values
        data_column_suffix = ''

    sorted_categories = avg_values.sort_values(ascending=False).index.tolist()

    n = len(sorted_categories)
    ncols = 3
    nrows = n // ncols + (n % ncols > 0)

    fig, axes = plt.subplots(nrows=nrows, ncols=ncols, figsize=(15, nrows*4), squeeze=False)
    axes = axes.flatten()

    for i, curr_category in enumerate(sorted_categories):
        category_data = df_revenue_percentage[df_revenue_percentage[category] == curr_category].copy()
        category_data['week_number'] = category_data['date'].dt.isocalendar().week.astype(int)

        for metric in metrics:
            label_suffix = ' %' if show_by == "percentage" else ' Abs'
            data_column_name = f'{metric}{data_column_suffix}'
            axes[i].plot(category_data['week_number'], category_data[data_column_name], label=f'{metric}{label_suffix}')

        axes[i].set_title(f'Category: {curr_category} - {y_label} {("Percentage" if show_by == "percentage" else "Absolute")}')
        axes[i].legend()
        axes[i].set_xlabel('Week Number')
        axes[i].set_ylabel(y_label + (' %' if show_by == "percentage" else ''))

    # Hide any empty subplots
    for j in range(i+1, len(axes)):
        fig.delaxes(axes[j])

    fig.tight_layout()
    plt.show()