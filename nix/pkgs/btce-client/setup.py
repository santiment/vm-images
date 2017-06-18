from setuptools import setup, find_packages

setup(
    name="btce-trollbox-datafeed",
    version="0.1",
    packages=find_packages(),
    scripts = ['collect-chat.py']
    )
