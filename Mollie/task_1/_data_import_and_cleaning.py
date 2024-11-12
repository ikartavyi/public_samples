# Global imports
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import datetime as dt
import re

df_org = pd.read_csv('./datasets/organizations.csv', parse_dates=['first_payment_date'])
df_methods = pd.read_csv('./datasets/payment_methods.csv')
df_payments = pd.read_csv('./datasets/payments.csv', parse_dates=['payment_month'])

dates = (df_payments.payment_month.min(), df_payments.payment_month.max())

# Forming the core dataframe that I will use to analyze the numbers.
df = (
    pd.merge(
        df_org, 
        (
            pd.date_range(start=dates[0], end=dates[1], freq='MS')
            .to_frame(index=False, name='payment_month')
        ), 
        how='cross'
    )
    .assign(
        first_payment_month= lambda x: x['first_payment_date'].dt.to_period('M').dt.to_timestamp()
    )
    .where(lambda x: x['payment_month'] >= x['first_payment_month'])
    .dropna()
    .merge(df_payments, on=['customer_id', 'payment_month'], how='left')
)

# Adding the payment method additional info
df = (
    df
    .merge(df_methods, on='payment_method_id', how='left')
    .assign(
        fixed_rate_comission=lambda x: x['total_transactions'] * x['fixed_rate'],
        variable_rate_comission=lambda x: x['total_volume'] * x['variable_rate'],
        total_comission=lambda x: x['fixed_rate_comission'] + x['variable_rate_comission']
    )
)

n_a_fill_cols = [
    x for x in df.columns if x not in ['first_payment_date', 'payment_month', 'payment_method_id', 'customer_id']
]

df[n_a_fill_cols] = df[n_a_fill_cols].fillna(0)

display(df.head())

# Setting the style parameters
palette = sns.color_palette('Spectral', 5)
palette.reverse()
sns.set_theme(style='white', palette=palette)
palette
