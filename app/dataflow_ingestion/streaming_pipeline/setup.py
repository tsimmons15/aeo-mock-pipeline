from setuptools import setup, find_packages

setup(
    name="aeo-streaming-pipeline",
    version="1.0.0",
    packages=find_packages(exclude=["tests", "tests.*"]),
    python_requires=">=3.7",
    install_requires=[
        "aeo-transforms==1.0.0",
        "apache-beam[gcp]",
    ],
)