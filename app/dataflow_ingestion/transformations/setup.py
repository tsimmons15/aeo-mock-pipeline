from setuptools import setup, find_packages

setup(
    name="aeo-transforms",
    version="1.0.0",
    description="Shared Apache Beam transforms for AEO Dataflow pipelines",
    packages=find_packages(exclude=["tests", "tests.*"]),
    python_requires=">=3.7",
    install_requires=[
        "apache-beam[gcp]",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0",
            "pytest-cov",
        ]
    },
)